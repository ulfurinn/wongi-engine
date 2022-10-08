module Wongi::Engine
  module DSL::Action
    class ErrorGenerator < BaseAction
      def initialize(message = nil, &messenger)
        super()
        @message = message
        @messenger = messenger
      end

      def rete=(*)
        super
        rete.add_collector self, :error
      end

      def errors
        production.tokens.map do |token|
          message = if @messenger
                      @messenger.call token.assignments
                    else
                      @message
                    end
          ReteError.new token, message, literate?
        end
      end

      def literate?
        !@messenger.nil?
      end
    end
  end
end
