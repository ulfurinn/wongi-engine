module Wongi::Engine
  module DSL::Clause
    class Aggregate < Has

      attr_reader :member
      attr_reader :function

      def initialize(s, p, o, options = {})
        @member, @function = options[:on], options[:function]
        super
      end

      def compile(context)
        tests, assignment = parse_variables(context)
        context.tap { |c| c.aggregate_node(self, tests, assignment, member, function) }
      end
    end
  end
end
