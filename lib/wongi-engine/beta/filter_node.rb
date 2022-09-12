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
        if test.passes? token
          children.each do |child|
            child.beta_activate Token.new(child, token, nil, {})
          end
        end
      end

      def beta_deactivate(token)
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
              # token.destroy
            end
          end
        end
      end

      def equivalent?(test)
        test == self.test
      end

      def refresh_child(child)
        tmp = children
        self.children = [child]
        parent.tokens.each do |token|
          beta_activate token
        end
        self.children = tmp
      end
    end
  end
end
