module Wongi::Engine

  class DSL::Query < DSL::Rule

    def search_on *terms
      terms.each { |term| parameters << term }
    end

    def import_into model
      super.tap { |copy| copy.search_on *parameters }
    end

    def parameters
      @parameters ||= []
    end

    def install( rete )
      rete.install_query( self )
    end

  end

end
