module Wongi::Engine
  module DSL::Action
    class AssignAction < SimpleAction
      def initialize(var, &action)
        super(action)
        @var = var
      end

      def execute(token)
        value = super
        token.set(@var, value)
      end
    end
  end
end
