require 'wongi-engine/network/collectable'
require 'wongi-engine/network/debug'

module Wongi::Engine
  class Network

    attr_reader :alpha_top, :beta_top
    attr_reader :queries, :results
    attr_reader :productions

    include NetworkParts::Collectable

    protected
    attr_accessor :alpha_hash
    attr_writer :alpha_top, :beta_top
    attr_writer :queries, :results

    public

    def debug!
      extend NetworkParts::Debug
    end

    def initialize
      @timeline = []
      self.alpha_top = AlphaMemory.new( Template.new( :_, :_, :_ ), self )
      self.alpha_hash = { Template.hash_for( :_, :_, :_ ) => self.alpha_top }
      self.beta_top = BetaMemory.new(nil)
      self.beta_top.rete = self
      self.beta_top.seed
      self.queries = {}
      self.results = {}
      @cache = {}
      @revns = {}
      @contexts = {}

      @productions = { }

      @collectors = {}
      @collectors[:error] = []

    end

    def dump
      beta_top.dump
    end

    def alphas
      alpha_hash.values
    end

    def import thing
      case thing
      when String, Numeric, TrueClass, FalseClass, NilClass
        thing
      when Symbol
        thing
      else
        raise "I don't know how to import a #{thing.class}"
      end
    end

    def assert wme

      unless wme.rete == self
        wme = wme.import_into self
      end

      if @current_context
        @current_context.asserted_wmes << wme
        wme.context = @current_context
      end

      return if @cache.has_key?(wme)

      # puts "ASSERTING #{wme}"
      @cache[wme] = wme

      s = wme.subject
      p = wme.predicate
      o = wme.object

      alpha_activate(lookup( s,  p,  o), wme)
      alpha_activate(lookup( s,  p, :_), wme)
      alpha_activate(lookup( s, :_,  o), wme)
      alpha_activate(lookup(:_,  p,  o), wme)
      alpha_activate(lookup( s, :_, :_), wme)
      alpha_activate(lookup(:_,  p, :_), wme)
      alpha_activate(lookup(:_, :_,  o), wme)
      alpha_activate(lookup(:_, :_, :_), wme)

      wme
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
          @timeline[index+1]
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

    def rule name = nil, &block
      r = ProductionRule.new( name || generate_rule_name )
      r.instance_eval &block
      self << r
    end

    def query name, &block
      q = Query.new name
      q.instance_eval &block
      self << q
    end

    def << something
      case something
      when Array
        if something.length == 3
          assert WME.new( *something )
        else
          raise "Arrays must have 3 elements"
        end
      when ProductionRule
        derived = something.import_into self
        production = add_production derived.conditions, derived.actions
        if something.name
          productions[ something.name ] = production
        end
      when Query
        derived = something.import_into self
        prepare_query derived.name, derived.conditions, derived.parameters, derived.actions
      when Ruleset
        something.install self
      when WME
        assert something
      #when Wongi::RDF::Document
        #  something.statements.each do |st|
        #    assert WME.new( st.subject, st.predicate, st.object, self )
        #  end
      when Rete
        something.each do |st|
          assert st.import_into( self )
        end
      else
        raise "I don't know how to accept a #{something.class}"
      end
    end

    def retract wme, is_real = false

      if wme.is_a? Array
        return retract( WME.new(*wme), is_real )
      end

      if ! is_real
        if @current_context
          @current_context.retracted_wmes << wme
        end
      end

      real = if is_real
        wme
      else
        #find(wme.subject, wme.predicate, wme.object)
        @cache[wme]
      end

      return false if real.nil?
      @cache.delete(real)
      raise "Cannot retract inferred statements" unless real.manual?

      real.destroy

      true

    end

    def compile_alpha condition
      template = Template.new :_, :_, :_
      time = condition.time

      template.subject = condition.subject unless Template.variable?( condition.subject )
      template.predicate = condition.predicate unless Template.variable?( condition.predicate )
      template.object = condition.object unless Template.variable?( condition.object )

      hash = template.hash
      # puts "COMPILED CONDITION #{condition} WITH KEY #{key}"
      if time == 0
        return self.alpha_hash[ hash ] if self.alpha_hash.has_key?( hash )
      else
        return @timeline[time+1][ hash ] if @timeline[time+1] && @timeline[time+1].has_key?( hash )
      end

      alpha = AlphaMemory.new( template, self )

      if time == 0
        self.alpha_hash[ hash ] = alpha
        initial_fill alpha
      else
        if @timeline[time+1].nil?
          # => ensure lineage from 0 to time
          compile_alpha condition.class.new(condition.subject, condition.predicate, condition.object, time + 1)
          @timeline.unshift Hash.new
        end
        @timeline[time+1][ hash ] = alpha
      end
      alpha
    end

    def cache s, p, o
      compile_alpha Template.new(s, p, o).import_into( self )
    end

    def initial_fill alpha
      tpl = alpha.template
      source = more_generic_alpha(tpl)
      # puts "more efficient by #{alpha_top.wmes.size - source.wmes.size}" unless source ==
      # alpha_top
      source.wmes.each do |wme|
        alpha.activate wme if wme =~ tpl
      end
    end

    def add_production conditions, actions = []
      real_add_production self.beta_top, conditions, [], actions, false
    end

    def remove_production pnode
      delete_node_with_ancestors pnode
    end

    def prepare_query name, conditions, parameters, actions = []
      query = self.queries[ name ] = BetaMemory.new( nil )
      query.rete = self
      transformed = {}
      parameters.each { |param| transformed[param] = nil }
      query.seed transformed
      self.results[ name ] = real_add_production query, conditions, parameters, actions, true
    end

    def execute name, valuations
      beta = self.queries[name]
      raise "Undefined query #{name}; known queries are #{queries.keys}" unless beta
      beta.subst valuations
    end

    def inspect
      "<Rete>"
    end

    def context= name
      if name && !@contexts.has_key?(name)
        @current_context = (@contexts[name] ||= ModelContext.new name)
      end
    end

    def retract_context name
      return unless @contexts.has_key?(name)

      if @current_context && @current_context.name == name
        @current_context = nil
      end
      ctx = @contexts[name]
      ctx.asserted_wmes.select { |wme| wme.generating_tokens.empty?  }.each { |wme| retract(wme, true) }
      ctx.retracted_wmes.each { |wme| assert(wme) }
      @contexts.delete name
    end

    def exists? wme
      @cache[ wme ]
    end

    def each *args
      return unless block_given?
      unless args.length == 0 || args.length == 3
        raise "Document#each expects a pattern or nothing at all"
      end
      s, p, o = if args.empty?
        [:_, :_, :_]
      else
        args
      end
      no_check = s == :_ && p == :_ && o == :_
      template = Template.new(s, p, o).import_into self
      alpha_top.wmes.each do |wme|
        yield wme if (no_check || wme =~ template)
      end
    end

    def select s, p, o
      template = Template.new(s, p, o).import_into self
      matching = alpha_top.wmes.select { |wme| wme =~ template }
      if block_given?
        matching.each { |st| yield st.subject, st.predicate, st.object }
      end
      matching
    end

    def find s, p, o
      template = Template.new(s, p, o).import_into self
      source = best_alpha(template)
      # puts "looking for #{template} among #{source.wmes.size} triples of #{source.template}"
      source.wmes.detect { |wme| wme =~ template }
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

    def lookup s, p, o
      key = Template.hash_for(s, p, o)
      # puts "Lookup for #{key}"
      self.alpha_hash[ key ]
    end

    def alpha_activate alpha, wme
      alpha.activate(wme) if alpha
    end

    def more_generic_alpha template
      return alpha_top    # OPTIMISE => temporary; may use later or not use at all
      return alpha_top if template.root?
      more_generic_templates(template).reduce alpha_top do |best, template|
        alpha = alpha_hash[template.hash]
        if alpha && alpha.wmes.size < best.wmes.size
          alpha
        else
          best
        end
      end
    end

    def more_generic_templates template
      set = []
      set << template.with_subject( :_ ) unless template.subject == :_
      set << template.with_predicate( :_ ) unless template.predicate == :_
      set << template.with_object( :_ ) unless template.object == :_
      set.select { |item| not item.root? }
    end

    def best_alpha template
      raise
      candidates = alpha_hash.values.select do |alpha|
        template =~ alpha.template
      end
      result = candidates.inject do |best, alpha|
        if best.nil?
          alpha
        elsif alpha.wmes.length < best.wmes.length
          alpha
        else
          best
        end
      end
      puts "Best alpha for #{template} is #{result}"
      result
    end

    def real_add_production root, conditions, parameters, actions, alpha_deaf
      beta = root.network conditions, [], parameters, alpha_deaf

      production = ProductionNode.new( beta, actions )
      production.refresh
      production
    end

    def delete_node_with_ancestors node

      if node.kind_of?( NccNode )
        delete_node_with_ancestors node.partner
      end

      if [BetaMemory, NegNode, NccNode, NccPartner].any? { | klass| node.kind_of? klass }
        while node.tokens.first
          node.tokens.first.delete
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
