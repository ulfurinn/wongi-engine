module Wongi
  module Engine
    class NccPartner < BetaNode
      attr_accessor :ncc, :divergent

      def beta_activate(token)
        # p beta_activate: {class: self.class, object_id:, token:}
        return if tokens.find { |t| t.duplicate? token }

        overlay.add_token(token)

        owner = owner_for(token)
        return unless owner

        owner.ncc_results << token
        token.owner = owner
        owner.node.ncc_deactivate owner
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)

        owner = token.owner
        return unless owner

        owner.ncc_results.delete token
        ncc.ncc_activate owner if owner.ncc_results.empty?
      end

      def owner_for(token)
        # find a token in the NCC node that has the same lineage as this token:
        # - the NCC token will be a direct descendant of the divergent, therefore
        # - one of this token's ancestors will be a duplicate of that token
        # TODO: this should be more resilient, but child token creation does not allow for much else at the moment
        ncc.tokens.find { |t| token.ancestors.any? { |ancestor| ancestor.duplicate?(t) } }
      end
    end
  end
end
