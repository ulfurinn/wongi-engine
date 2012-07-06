module Wongi::Engine
  class GenerationClause

    def initialize s, p, o
      @triple = Template.new( s, p, o )
    end

    def import_into rete
      generator = StatementGenerator.new @triple.import_into( rete )
      generator.rete = rete
      generator
    end

  end
end
