module Wongi::Engine
  module DSL
    class AnyRule

      attr_reader :variants

      def initialize(&block)
        @variants = []
        if block
          instance_eval &block
        end
      end

      def option(&block)
        var = VariantRule.new
        var.forall &block
        variants << var
      end

      def compile(context)
        context.tap { |c| c.or_node(variants) }
      end

    end

    class VariantRule < Rule
      def initialize(name = nil)
        super
        @current_section = :forall
      end
    end
  end
end
