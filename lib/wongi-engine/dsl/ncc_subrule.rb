module Wongi::Engine
  class DSL::NccSubrule < DSL::Rule

    def initialize name = nil, &block
      super
      if block
        forall &block
      end
    end

    def compile context
      context.tap { |c| c.ncc_node(self, false) }
    end
  end
end
