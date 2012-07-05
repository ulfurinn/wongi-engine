module Wongi::Engine

  class Template < Struct.new( :subject, :predicate, :object, :time )

    include CoreExt

    attr_predicate debug: false

    def self.variable? thing
      Symbol === thing && thing =~ /^[A-Z]/
    end

    def initialize s = nil, p = nil, o = nil, time = 0
      raise "Cannot work with continuous time" unless time.integer?
      raise "Cannot look into the future" if time > 0
      super
    end

    def import_into r
      self.class.new r.import( subject ), r.import( predicate ), r.import( object ), time
    end

    def root?
      subject.nil? && predicate.nil? && object.nil?
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
      return false unless Template === template
      subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~ template
      case template
      when Template
        ( template.subject.nil? || template.subject == subject ) &&
            ( template.predicate.nil? || template.predicate == predicate ) &&
            ( template.object.nil? || template.object == object )
      else
        raise "Templates can only match templates"
      end
    end


    def compile context
      tests, assignment = *JoinNode.compile( self, context.earlier, context.parameters )
      alpha = context.rete.compile_alpha( self )
      context.node = context.node.beta_memory.join_node( alpha, tests, assignment, context.alpha_deaf )
      context.earlier << self
      context
    end

    def inspect
      "<Template #{subject.inspect} #{predicate.inspect} #{object.inspect} #{time}>"
    end

    def to_s
      inspect
    end

    private

    def array_form
      @array_form ||= [ subject, predicate, object ]
    end

  end

end
