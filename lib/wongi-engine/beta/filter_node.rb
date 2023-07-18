module Wongi
  module Engine
    class FilterNode < BetaNode
      # @return [Wongi::Engine::FilterTest]
      attr_accessor :test

      def initialize(parent, test)
        super parent
        self.test = test
      end

      def beta_activate(token)
        return unless test.passes?(token)

        overlay.add_token(token)

        children.each do |child|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end

      def beta_deactivate(token)
        overlay.remove_token(token)
        beta_deactivate_children(token: token)
      end

      def equivalent?(test)
        test == self.test
      end

      def refresh_child(child)
        tokens.select { test.passes?(_1) }.each do |token|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end
    end
  end
end
