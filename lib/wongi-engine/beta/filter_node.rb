module Wongi
  module Engine

    class FilterNode < BetaNode

      attr_accessor :test

      def initialize parent, test
        super parent
        self.test = test
      end

      def beta_activate token, wme = nil, assignments = { }
        if test.passes? token
          propagate_activation token, nil, {}
        end
      end

      def equivalent? test
        test == self.test
      end

      def refresh_child child
        tmp = children
        self.children = [ child ]
        parent.tokens.each do |token|
          beta_activate token
        end
        self.children = tmp
      end

    end

  end
end
