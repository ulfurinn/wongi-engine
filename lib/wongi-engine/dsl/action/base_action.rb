module Wongi::Engine
  module DSL::Action
    class BaseAction
      include CoreExt
      attr_accessor :production, :rule, :name, :rete

      def overlay = rete.current_overlay
    end
  end
end
