module Wongi::Engine

  WME = Struct.new(:subject, :predicate, :object) do

    include CoreExt

    attr_reader :rete

    attr_reader :generating_tokens
    attr_reader :neg_join_results, :opt_join_results
    attr_accessor :overlay
    attr_predicate :deleted
    attr_predicate :manual

    def initialize(s, p, o, r = nil)

      manual!

      @deleted = false
      @alphas = []
      @generating_tokens = []
      @neg_join_results = []
      @opt_join_results = []

      @rete = r

      # TODO: reintroduce Network#import when bringing back RDF support
      super(s, p, o)

    end

    def import_into(r)
      self.class.new(subject, predicate, object, r).tap do |wme|
        wme.overlay = overlay
        wme.manual = self.manual?
      end
    end

    def dup
      self.class.new(subject, predicate, object, rete).tap do |wme|
        wme.overlay = overlay
        wme.manual = self.manual?
      end
    end

    def ==(other)
      subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~(template)
      raise Wongi::Engine::Error, "Cannot match a WME against a #{template.class}" unless Template === template

      result = match_member(self.subject, template.subject) & match_member(self.predicate, template.predicate) & match_member(self.object, template.object)
      result if result.match?
    end

    def generated?
      !generating_tokens.empty?
    end

    def inspect
      "{#{subject.inspect} #{predicate.inspect} #{object.inspect}}"
    end

    def to_s
      inspect
    end

    def hash
      @hash ||= [subject.hash, predicate.hash, object.hash].hash
    end

    protected

    def match_member(mine, theirs)
      result = WMEMatchData.new
      if theirs == :_ || mine == theirs
        result.match!
      elsif Template.variable? theirs
        result.match!
        result[theirs] = mine
      end
      result
    end

  end

end
