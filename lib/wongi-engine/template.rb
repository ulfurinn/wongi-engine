module Wongi::Engine

  class Template < Struct.new( :subject, :predicate, :object, :time )

    include CoreExt

    attr_reader :filters
    attr_predicate debug: false

    def self.variable? thing
      Symbol === thing && thing =~ /^[A-Z]/
    end

    def initialize s = :_, p = :_, o = :_, time = 0
      raise "Cannot work with continuous time" unless time.integer?
      raise "Cannot look into the future" if time > 0
      super
      @filters = []
    end

    def import_into r
      copy = self.class.new r.import( subject ), r.import( predicate ), r.import( object ), time
      @filters.each { |f| copy.filters << f }
      copy
    end

    def root?
      subject == :_ && predicate == :_ && object == :_
    end

    def variables
      array_form.select { |e| self.class.variable? e }
    end

    def contains? var
      self.class.variable?( var ) && array_form.include?( var )
    end

    def hash
      @hash ||= array_form.map( &:hash ).hash
    end

    def self.hash_for *args
      args.map( &:hash ).hash
    end

    def === wme
      wme =~ self if WME === wme
    end

    def == other
      return false unless Template === other
      subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~ template
      case template
      when Template
        ( template.subject == :_ || template.subject == subject ) &&
        ( template.predicate == :_ || template.predicate == predicate ) &&
        ( template.object == :_ || template.object == object )
      else
        raise "Templates can only match templates"
      end
    end


    def compile context
      tests, assignment = *JoinNode.compile( self, context.earlier, context.parameters )
      alpha = context.rete.compile_alpha( self )
      context.node = context.node.beta_memory.join_node( alpha, tests, assignment, @filters, context.alpha_deaf )
      context.earlier << self
      context
    end

    def inspect
      "<~ #{subject.inspect} #{predicate.inspect} #{object.inspect} #{time}>"
    end

    def to_s
      inspect
    end

    private

    def array_form
      @array_form ||= [ subject, predicate, object ]
    end

  end

  class NegTemplate < Template
    # :arg: context => Wongi::Rete::BetaNode::CompilationContext
    def compile context
      tests, assignment = *JoinNode.compile( self, context.earlier, context.parameters )
      raise DefinitionError.new("Negative matches may not introduce new variables: #{assignment.variables}") unless assignment.root?
      alpha = context.rete.compile_alpha( self )
      context.node = context.node.neg_node( alpha, tests, context.alpha_deaf )
      context.node.debug = debug?
      context.earlier << self
      context
    end
  end

  class OptionalTemplate < Template

    def compile context
      tests, assignment = *JoinNode.compile( self, context.earlier, context.parameters )
      alpha = context.rete.compile_alpha( self )
      context.node = context.node.beta_memory.optional_node( alpha, tests, assignment, context.alpha_deaf )
      context.node.debug = debug?
      context.earlier << self
      context
    end

  end



end
