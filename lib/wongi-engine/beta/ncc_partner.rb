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
    end
  end
end
