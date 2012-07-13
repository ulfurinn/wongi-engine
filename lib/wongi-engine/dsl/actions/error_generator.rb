module Wongi
  module Engine
    class ReteError

      attr_reader :token, :message
      def initialize token, message, literate
        @token, @message, @literate = token, message, literate
      end
      def literate?
        @literate
      end
    end

    class ErrorGenerator < Wongi::Engine::Action

      def initialize message = nil, &messenger
        @message, @messenger = message, messenger
      end

      def rete=
        super
        rete.add_collector :error, self
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
