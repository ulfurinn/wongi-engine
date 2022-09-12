module Wongi::Engine
  module DSL::Action
    class ErrorGenerator < Base
      def initialize message = nil, &messenger
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
        not @messenger.nil?
      end
    end
  end
end
