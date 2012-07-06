module Wongi
  module Engine


    class FilterTest

      def passes? token
        true
      end

      def compile context
        context.node = context.node.beta_memory.filter_node( self )
        context.earlier << self
        context
      end

    end

    class EqualityTest < FilterTest
      def initialize x, y
        @x, @y = x, y
      end

      def passes? token

        x = if Template.variable? @x
          token[@x]
        else
          @x
        end

        y = if Template.variable? @y
          token[@y]
        else
          @y
        end

        return false if x.nil? || y.nil?
        return x == y

      end
    end

    class InequalityTest < FilterTest
      def initialize x, y
        @x, @y = x, y
      end

      def passes? token

        x = if Template.variable? @x
          token[@x]
        else
          @x
        end

        y = if Template.variable? @y
          token[@y]
        else
          @y
        end

        return false if x.nil? || y.nil?
        return x != y

      end
    end

    class FilterNode < BetaNode

      attr_accessor :test

      def initialize parent, test
        super parent
        self.test = test
      end

      def left_activate token
        if test.passes? token
          propagate_activation token, nil, {}
        end
      end
    end
  end
end
