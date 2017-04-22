module Wongi
  module Engine
    class NccPartner < BetaNode
      include TokenContainer

      attr_accessor :ncc
      attr_accessor :divergent

      def beta_activate token
        t = Token.new self, token, nil, {}
        owner = owner_for( t )
        return unless t.overlay
        t.overlay.add_token(t, self)
        if owner
          owner.ncc_results << t
          t.owner = owner
          owner.node.ncc_deactivate owner
        end
      end

      def beta_deactivate t
        token = tokens.find { |tok| tok.parent == t }
        return unless token
        token.overlay.remove_token(token, self)
        if owner = token.owner
          owner.ncc_results.delete token
          if owner.ncc_results.empty?
            ncc.ncc_activate owner
          end
        end
      end

      private

      def owner_for token
        divergent_token = token.ancestors.find { |t| t.node == divergent }
        ncc.tokens.find { |t| t.ancestors.include? divergent_token }
      end
    end
  end
end
