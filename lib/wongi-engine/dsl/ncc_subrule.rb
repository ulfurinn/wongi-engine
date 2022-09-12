module Wongi::Engine
  module DSL
    class NccSubrule < Rule
      def initialize(name = nil, &block)
        super
        forall(&block) if block
      end

      def compile(context)
        context.tap { |c| c.ncc_node(self, false) }
      end
    end
  end
end
