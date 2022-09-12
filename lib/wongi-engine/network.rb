require 'wongi-engine/network/collectable'
require 'wongi-engine/network/debug'

module Wongi::Engine
  class Network

    attr_reader :alpha_top, :beta_top
    attr_reader :queries, :results
    attr_reader :productions
    attr_reader :overlays

    include NetworkParts::Collectable

    protected

    attr_accessor :alpha_hash
    attr_writer :alpha_top, :beta_top
    attr_writer :queries, :results

    public

    def debug!
      extend NetworkParts::Debug
    end

    def rdf!
      unless defined? Wongi::RDF::DocumentSupport
        begin
          require 'wongi-rdf'
        rescue LoadError => e
          raise "'wongi-rdf' is required for RDF support"
        end
      end

      extend Wongi::RDF::DocumentSupport

      class << self
        def statements
          alpha_top.wmes
        end
      end

      @namespaces = {}
      @blank_counter = 1
      @ns_counter = 0
      @used_blanks = {}
    end

    def initialize
      @timeline = []
      self.alpha_top = AlphaMemory.new(Template.new(:_, :_, :_), self)
      self.alpha_hash = { alpha_top.template.hash => alpha_top }
      self.beta_top = BetaMemory.new(nil)
      self.beta_top.rete = self
      self.beta_top.seed
      self.queries = {}
      self.results = {}
      @revns = {}

      @productions = {}

      @collectors = {}
      @collectors[:error] = []

    end

    def dump
      beta_top.dump
    end

    def with_overlay(&block)
      default_overlay.with_child(&block)
    end

    def alphas
      alpha_hash.values
    end

    # def import thing
    #   case thing
    #   when String, Numeric, TrueClass, FalseClass, NilClass, Wongi::RDF::Node
    #     thing
    #   when Symbol
    #     thing
    #   else
    #     thing
    #   end
    # end

    def default_overlay
      @default_overlay ||= DataOverlay.new(self)
    end

    # @private
    def add_overlay(o)
      overlays << o
    end

    # @private
    def remove_overlay(o)
      overlays.delete(o) unless o == default_overlay
    end

    # @private
    def current_overlay
      overlays.last
    end

    # @private
    def overlays
      @overlays ||= []
    end

    def assert(wme)
      default_overlay.assert(wme)
    end

    def retract(wme, options = {})
      default_overlay.retract(wme, options)
    end

    # @private
    def real_assert(wme)
      unless wme.rete == self
        wme = wme.import_into self
      end

      # source = best_alpha(wme)
      if (existing = find(wme.subject, wme.predicate, wme.object))
        existing.manual! if wme.manual?
        return
      end

      alphas_for(wme).each { |a| a.activate wme }

      wme
    end

    # @private
    def real_retract(wme, options)
      real = find(wme.subject, wme.predicate, wme.object)
      return if real.nil?
      if real.generated? # still some generator tokens left
        if real.manual?
          real.manual = false
        else
          raise Error, "cannot retract automatic facts"
        end
      else
        if options[:automatic] && real.manual? # auto-retracting a fact that has been added manually
          return
        end
      end

      alphas_for(real).each { |a| a.deactivate real }
    end

    def wmes
      alpha_top.wmes
    end

    alias_method :statements, :wmes
    alias_method :facts, :wmes

    def in_snapshot?
      @in_snapshot
    end

    def snapshot!
      @timeline.each_with_index do |slice, index|
        source = if index == @timeline.size - 1
                   alpha_hash
                 else
                   @timeline[index + 1]
                 end
        # puts "source = #{source}"
        wmes = {}
        slice.each { |key, alpha| wmes[key] = alpha.wmes }
        slice.each do |key, alpha|
          in_snapshot {
            wmes[key].dup.each { |wme| wme.destroy }
          }
          alpha.snapshot! source[key]
        end
      end
    end

    def rule(name = nil, &block)
      r = DSL::Rule.new(name || generate_rule_name)
      r.instance_eval &block
      self << r
    end

    def query(name, &block)
      q = DSL::Query.new name
      q.instance_eval &block
      self << q
    end

    def <<(something)
      if something.respond_to?(:install)
        something.install(self)
      else
        case something
        when Array
          assert WME.new(*something).tap { |wme| wme.overlay = default_overlay }
        when WME
          assert something
          # when Wongi::RDF::Statement
          #   assert WME.new( something.subject, something.predicate, something.object, self )
          #when Wongi::RDF::Document
          #  something.statements.each do |st|
          #    assert WME.new( st.subject, st.predicate, st.object, self )
          #  end
        when Network
          something.wmes.each { |wme| assert(wme) }
        else
          raise Error, "I don't know how to accept a #{something.class}"
        end
      end
    end

    def install_rule(rule)
      derived = rule.import_into self
      production = build_production beta_top, derived.conditions, [], derived.actions, false
      if rule.name
        productions[rule.name] = production
      end
      production
    end

    def install_query(query)
      derived = query.import_into self
      prepare_query derived.name, derived.conditions, derived.parameters, derived.actions
    end

    def compile_alpha(condition)
      template = Template.new :_, :_, :_
      time = condition.time

      template.subject = condition.subject unless Template.variable?(condition.subject)
      template.predicate = condition.predicate unless Template.variable?(condition.predicate)
      template.object = condition.object unless Template.variable?(condition.object)

      hash = template.hash
      # puts "COMPILED CONDITION #{condition} WITH KEY #{key}"
      if time == 0
        return self.alpha_hash[hash] if self.alpha_hash.has_key?(hash)
      else
        return @timeline[time + 1][hash] if @timeline[time + 1] && @timeline[time + 1].has_key?(hash)
      end

      alpha = AlphaMemory.new(template, self)

      if time == 0
        self.alpha_hash[hash] = alpha
        initial_fill alpha
      else
        if @timeline[time + 1].nil?
          # => ensure lineage from 0 to time
          compile_alpha condition.class.new(condition.subject, condition.predicate, condition.object, time: time + 1)
          @timeline.unshift Hash.new
        end
        @timeline[time + 1][hash] = alpha
      end
      alpha
    end

    def cache(s, p, o)
      compile_alpha Template.new(s, p, o)
    end

    # TODO: pick an alpha with fewer candidates to go through
    def initial_fill(alpha)
      alpha_top.wmes.each do |wme|
        alpha.activate wme if wme =~ alpha.template
      end
    end

    def remove_production(pnode)
      delete_node_with_ancestors pnode
    end

    def prepare_query(name, conditions, parameters, actions = [])
      query = self.queries[name] = BetaMemory.new(nil)
      query.rete = self
      query.seed(Hash[parameters.map { |param| [param, nil] }])
      self.results[name] = build_production query, conditions, parameters, actions, true
    end

    def execute(name, valuations)
      beta = self.queries[name]
      raise Error, "Undefined query #{name}; known queries are #{queries.keys}" unless beta
      beta.subst valuations
    end

    def inspect
      "<Rete>"
    end

    def exists?(wme)
      find(wme.subject, wme.predicate, wme.object)
    end

    def each(*args, &block)
      template = case args.length
                 when 0
                   Template.new(:_, :_, :_)
                 when 3
                   Template.new(*args)
                 else
                   raise Error, "Network#each expect a template or nothing at all"
                 end
      source = best_alpha(template)
      matching = current_overlay.wmes(source).select { |wme| wme =~ template }
      if block_given?
        matching.each(&block)
      else
        matching.each
      end
    end

    def select(s, p, o)
      template = Template.new(s, p, o)
      source = best_alpha(template)
      matching = current_overlay.wmes(source).select { |wme| wme =~ template }
      if block_given?
        matching.each { |st| yield st.subject, st.predicate, st.object }
      end
      matching
    end

    def find(s, p, o)
      template = Template.new(s, p, o)
      source = best_alpha(template)
      # puts "looking for #{template} among #{source.wmes.size} triples of #{source.template}"
      current_overlay.wmes(source).find { |wme| wme =~ template }
    end

    protected

    def in_snapshot
      @in_snapshot = true
      yield
    ensure
      @in_snapshot = false
    end

    def generate_rule_name
      "rule_#{productions.length}"
    end

    def alphas_for(wme)
      s, p, o = wme.subject, wme.predicate, wme.object
      [
        lookup(s, p, o),
        lookup(s, p, :_),
        lookup(s, :_, o),
        lookup(:_, p, o),
        lookup(s, :_, :_),
        lookup(:_, p, :_),
        lookup(:_, :_, o),
        lookup(:_, :_, :_),
      ].compact!.tap(&:uniq!)
    end

    def lookup(s, p, o)
      key = Template.hash_for(s, p, o)
      # puts "Lookup for #{key}"
      self.alpha_hash[key]
    end

    def alpha_activate(alpha, wme)
      alpha.activate(wme)
    end

    def best_alpha(template)
      alpha_hash.inject(nil) do |best, (_, alpha)|
        if template =~ alpha.template && (best.nil? || alpha.size < best.size)
          alpha
        else
          best
        end
      end
    end

    def build_production(root, conditions, parameters, actions, alpha_deaf)
      compiler = Compiler.new(self, root, conditions, parameters, alpha_deaf)
      ProductionNode.new(compiler.compile, actions).tap do |production|
        production.compilation_context = compiler
        production.refresh
      end
    end

    def delete_node_with_ancestors(node)

      if node.kind_of?(NccNode)
        delete_node_with_ancestors node.partner
      end

      # the root node should not be deleted
      return unless node.parent

      if [BetaMemory, NegNode, NccNode, NccPartner].any? { |klass| node.kind_of? klass }
        while node.tokens.first
          node.tokens.first.destroy
        end
      end

      if node.parent
        node.parent.children.delete node
        if node.parent.children.empty?
          delete_node_with_ancestors(node.parent)
        end
      end

    end

  end

end
