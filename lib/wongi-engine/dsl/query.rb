module Wongi::Engine

  class Query < GenericProductionRule

    attr_reader :parameters

    def initialize name
      super
      @parameters = []
    end

    def search_on *terms
      terms.each { |term| @parameters << term }
    end

    def import_into model
      copy = super
      copy.search_on *@parameters
      copy
    end

  end

end
