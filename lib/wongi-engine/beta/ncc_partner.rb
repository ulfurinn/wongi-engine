module Wongi
  module Engine
    class NccPartner < BetaNode

      attr_reader :tokens
      #  attr_accessor :conjuncts
      attr_accessor :ncc
      attr_accessor :divergent

      def initialize parent
        super
        #    @conjuncts = 0
        @tokens = []
      end

      def left_activate token
        t = Token.new token, nil, {}
        t.node = self
        owner = ncc.tokens.find do |ncc_token|
          ncc_token.parent.node == divergent
        end
        if owner
          owner.ncc_results << t
          t.owner = owner
          owner.delete_children
        else
          tokens << t
        end
      end

      def delete_token token
        token.owner.ncc_results.delete token
        if token.owner.ncc_results.empty?
          ncc.children.each do |node|
            node.left_activate token.owner, nil, {}
          end
        end

      end
    end
  end
end
