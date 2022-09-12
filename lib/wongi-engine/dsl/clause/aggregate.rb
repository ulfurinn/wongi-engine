module Wongi::Engine
  module DSL::Clause
    class Aggregate < Has

      attr_reader :map
      attr_reader :function
      attr_reader :assign

      def initialize(s, p, o, options = {})
        member = options[:on]
        @map = options[:map]
        @function = options[:function]
        @assign = options[:assign]
        if !@map
          @map = -> { _1.send(member) }
        end
        super
      end

      def compile(context)
        tests, assignment = parse_variables(context)
        context.tap { |c| c.aggregate_node(self, tests, assignment, map, function, assign) }
      end
    end
  end
end
