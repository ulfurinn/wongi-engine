module Wongi::Engine
  module DSL::Clause
    class Assign

      def initialize variable, &body
        @variable, @body = variable, body
        raise DefinitionError, "#{variable} is not a variable" unless Template.variable?(variable)
      end

      def compile context
        context.tap { |c| c.assignment_node(@variable, @body) }
      end
    end
  end
end
