module Wongi::Engine
  module DSL::Clause
    class Aggregate < Has
      attr_reader :map, :function, :assign

      def initialize(s, p, o, options = {})
        member = options[:on]
        @map = options[:map]
        @function = options[:function]
        @assign = options[:assign]
        @map ||= -> { _1.send(member) }
        super
      end

      def compile(context)
        tests, assignment = parse_variables(context)
        context.tap { |c| c.aggregate_node(self, tests, assignment, map, function, assign) }
      end
    end
  end
end
