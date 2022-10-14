module Wongi::Engine
  WME = Struct.new(:subject, :predicate, :object) do
    include CoreExt

    # attr_reader :neg_join_results, :opt_join_results

    def self.from_concrete_template(template)
      raise "template #{template} is not concrete" unless template.concrete?

      new(template.subject, template.predicate, template.object)
    end

    def dup
      self.class.new(subject, predicate, object)
    end

    def ==(other)
      other && subject == other.subject && predicate == other.predicate && object == other.object
    end

    # @param template Wongi::Engine::Template
    def =~(template)
      raise Wongi::Engine::Error, "Cannot match a WME against a #{template.class}" unless template.is_a?(Template)

      result = match_member(subject, template.subject) & match_member(predicate, template.predicate) & match_member(object, template.object)
      result if result.match?
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

    def eql?(other)
      subject.eql?(other.subject) && predicate.eql?(other.predicate) && object.eql?(other.object)
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
