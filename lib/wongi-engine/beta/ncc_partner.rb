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
        #    owners_t = t
        #  #  owners_w = t.wme
        #    conjuncts.times do
        #  #    owners_w = owners_t.wme
        #      owners_t = owners_t.parent
        #    end
        owner = nil
        ncc.tokens.each do |ncc_token|
          # if ncc_token.parent == owners_t
          if ncc_token.parent.node == divergent
            owner = ncc_token
            break
          end
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
