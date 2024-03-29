require 'wongi-engine/network/collectable'
require 'wongi-engine/network/debug'

module Wongi::Engine
  class Network
    include CoreExt
    attr_accessor :alpha_top, :beta_top, :queries, :results, :alpha_hash
    attr_reader :productions, :overlays

    attr_predicate :bypass_consistency_checks

    include NetworkParts::Collectable
    private :overlays
    private :alpha_hash, :alpha_hash=

    private :alpha_top=, :beta_top=, :queries=, :results=

    def debug!
      extend NetworkParts::Debug
    end

    def rdf!
      unless defined? Wongi::RDF::DocumentSupport
        begin
          require 'wongi-rdf'
        rescue LoadError
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
      @overlays = [base_overlay]

      self.alpha_top = AlphaMemory.new(Template.new(:_, :_, :_), self)
      self.alpha_hash = { alpha_top.template => alpha_top }
      self.beta_top = RootNode.new(nil)
      beta_top.rete = self
      beta_top.seed
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
      child = current_overlay.new_child
      add_overlay(child)
      block.call(child)
    ensure
      remove_overlay(child)
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

    def base_overlay
      @base_overlay ||= Overlay.new(self)
    end

    # TODO: deprecate this
    alias default_overlay base_overlay

    # @private
    private def add_overlay(o)
      overlays << o
    end

    # @private
    private def remove_overlay(o)
      overlays.delete(o) unless o == default_overlay
    end

    # @private
    def current_overlay
      overlays.last
    end

    def entity(subject)
      current_overlay.entity(subject)
    end

    def assert(wme)
      default_overlay.assert(wme)
    end

    def retract(wme, options = {})
      default_overlay.retract(wme, options)
    end

    # @private
    def real_assert(wme)
      alphas_for(wme).each { |a| a.activate wme }
      wme
    end

    # @private
    def real_retract(wme)
      # p real_retract: {wme:}
      alphas_for(wme).each { |a| a.deactivate wme }
    end

    def wmes
      each.to_a
    end

    alias statements wmes
    alias facts wmes

    def rule(name = nil, &block)
      r = DSL::Rule.new(name || generate_rule_name)
      r.instance_eval(&block)
      self << r
    end

    def query(name, &block)
      q = DSL::Query.new name
      q.instance_eval(&block)
      self << q
    end

    def <<(something)
      if something.respond_to?(:install)
        something.install(self)
      else
        case something
        when Array
          assert(WME.new(*something))
        when WME
          assert something
          # when Wongi::RDF::Statement
          #   assert WME.new( something.subject, something.predicate, something.object, self )
          # when Wongi::RDF::Document
          #  something.statements.each do |st|
          #    assert WME.new( st.subject, st.predicate, st.object, self )
          #  end
        when Network
          something.wmes.each { |wme| assert(wme) }
        else
          raise Error, "I don't know how to accept a #{something.class}"
        end
        self
      end
    end

    def install_rule(rule)
      derived = rule.import_into self
      production = build_production(rule.name, beta_top, derived.conditions, [], derived.actions, false)
      productions[rule.name] = production if rule.name
      production
    end

    def install_query(query)
      derived = query.import_into self
      prepare_query derived.name, derived.conditions, derived.parameters, derived.actions
    end

    def compile_alpha(condition)
      template = Template.new :_, :_, :_

      template.subject = condition.subject unless Template.variable?(condition.subject)
      template.predicate = condition.predicate unless Template.variable?(condition.predicate)
      template.object = condition.object unless Template.variable?(condition.object)

      # puts "COMPILED CONDITION #{condition} WITH KEY #{key}"
      return alpha_hash[template] if alpha_hash.key?(template)

      alpha = AlphaMemory.new(template, self)

      alpha_hash[template] = alpha
      initial_fill alpha

      alpha
    end

    def cache(s, p, o)
      compile_alpha Template.new(s, p, o)
    end

    def initial_fill(alpha)
      default_overlay.each(:_, :_, :_).to_a.each do |wme|
        alpha.activate wme if wme =~ alpha.template
      end
    end

    def remove_production(pnode)
      delete_node_with_ancestors pnode
    end

    def prepare_query(name, conditions, parameters, actions = [])
      query = queries[name] = RootNode.new(nil)
      query.rete = self
      query.seed(parameters.to_h { |param| [param, nil] })
      results[name] = build_production(name, query, conditions, parameters, actions, true)
    end

    def execute(name, valuations)
      beta = queries[name]
      raise Error, "Undefined query #{name}; known queries are #{queries.keys}" unless beta

      beta.subst valuations
    end

    def inspect
      "<Rete>"
    end

    def exists?(wme)
      !find(wme.subject, wme.predicate, wme.object).nil?
    end

    def each(*args, &block)
      current_overlay.each(*args, &block)
    end

    def select(*args, &block)
      each(*args, &block)
    end

    def find(*args)
      each(*args).first
    end

    protected

    def generate_rule_name
      "rule_#{productions.length}"
    end

    def alphas_for(wme)
      s = wme.subject
      p = wme.predicate
      o = wme.object
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
      key = Template.new(s, p, o)
      # puts "Lookup for #{key}"
      alpha_hash[key]
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

    def build_production(name, root, conditions, parameters, actions, alpha_deaf)
      compiler = Compiler.new(self, root, conditions, parameters, alpha_deaf)
      ProductionNode.new(name, compiler.compile, actions).tap do |production|
        production.compilation_context = compiler
        production.refresh
      end
    end

    def delete_node_with_ancestors(node)
      delete_node_with_ancestors node.partner if node.is_a?(NccNode)

      # the root node should not be deleted
      return unless node.parent

      node.tokens.dup.each do |token|
        overlays.each do |overlay|
          overlay.remove_own_token(token)
        end
      end

      node.parent.children.delete node
      delete_node_with_ancestors(node.parent) if node.parent.children.empty?
    end
  end
end
