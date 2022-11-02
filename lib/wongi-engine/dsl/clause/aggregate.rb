module Wongi::Engine
  module DSL::Clause
    class Aggregate
      attr_reader :var, :over, :partition, :aggregate, :map

      def initialize(var, options = {})
        @var = var
        @over = options[:over]
        @partition = options[:partition]
        @aggregate = options[:using]
        @map = options[:map]
      end

      def compile(context)
        context.tap { |c| c.aggregate_node(var, over, partition, aggregate, map) }
      end
    end
  end
end
