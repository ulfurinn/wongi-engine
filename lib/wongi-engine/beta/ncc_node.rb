module Wongi
  module Engine
    class NccSet

      attr_reader :children
      def initialize conditions
        @children = conditions
      end

      def compile context
        context.node = context.node.beta_memory.ncc_node( self, context.earlier, context.parameters, false )
        context.earlier << self
        context
      end

    end

    class NccNode < BetaNode

      attr_reader :tokens
      attr_accessor :partner

      def initialize parent
        super
        @tokens = []
      end

      #  def left_activate token, wme, assignments
      #    t = Token.new token, wme, assignments
      #    t.node = self
      def left_activate token, wme = nil, assignments = { } # => FIXME: left_activate has different signatures for storing and non-storing nodes...
        t = Token.new token, nil, {}
        t.node = self
        tokens << t
        partner.tokens.each do |ncc_token|
          t.ncc_results << ncc_token
          ncc_token.owner = t
        end
        if t.ncc_results.empty?
          children.each do |child|
            child.left_activate t, nil, {}
          end
        end
      end

      def refresh_child child
        tokens.each do |token|
          if token.ncc_results.empty?
            child.left_activate token, nil, {}
          end
        end
      end

      def delete_token token
        tokens.delete token
        token.ncc_results.each do |nccr|
          nccr.wme.tokens.delete nccr
          nccr.parent.children.delete nccr
        end
        token.ncc_results.clear
      end

    end
  end
end
