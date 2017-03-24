module Wongi::Engine
  module DSL::Action
    class AssignAction < SimpleAction
      def initialize(var, &action)
        @var = var
        @action = action
      end

      def execute(token)
        value = super
        token.set(@var, value)
      end
    end
  end
end
