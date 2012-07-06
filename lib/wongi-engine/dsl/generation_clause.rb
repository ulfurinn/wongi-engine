module Wongi::Engine
  class GenerationClause

    def initialize s, p, o
      @triple = Template.new( s, p, o )
    end

    def import_into model
      generator = StatementGenerator.new @triple.import_into( model )
      generator.model = model
      generator
    end

  end
end
