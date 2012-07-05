module Wongi::Engine

  class WMEMatchData

    attr_reader :assignments

    def initialize assignments = { }, match = false
      @assignments = assignments
      @match = match
    end

    def [] key
      assignments[key]
    end

    def []= key, value
      assignments[key] = value
    end

    def match?
      @match
    end

    def match!
      @match = true
    end

    def & other
      WMEMatchData.new( assignments.merge( other.assignments ), match? && other.match? )
    end

  end

end
