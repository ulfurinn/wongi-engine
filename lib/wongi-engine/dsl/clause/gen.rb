module Wongi::Engine
  module DSL::Clause
    class Gen
      def initialize(s, p, o)
        @triple = Template.new(s, p, o)
      end

      def import_into(rete)
        generator = DSL::Action::StatementGenerator.new @triple
        generator.rete = rete
        generator
      end
    end
  end
end
