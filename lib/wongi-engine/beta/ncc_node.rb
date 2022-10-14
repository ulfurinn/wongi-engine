module Wongi
  module Engine
    class NccNode < BetaNode
      attr_accessor :partner

      def beta_activate(token)
        # p beta_activate: {class: self.class, object_id:, token:}
        return if tokens.find { |t| t.duplicate? token }

        overlay.add_token(token)
        partner.tokens.each do |ncc_token|
          if partner.owner_for(ncc_token) == token
            overlay.add_ncc_token(token, ncc_token)
          end
        end
        return if overlay.ncc_tokens_for(token).any?

        children.each do |child|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)
        beta_deactivate_children(token: token)
      end

      def ncc_activate(token)
        # p ncc_activate: {class: self.class, object_id:, token:}
        children.each do |child|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end

      def ncc_deactivate(token)
        # p ncc_deactivate: {class: self.class, object_id:, token:}
        children.each do |beta|
          beta.tokens.select { |t| t.parent == token }.each do |t|
            beta.beta_deactivate t
          end
        end
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate Token.new(child, token, nil, {}) if overlay.ncc_tokens_for(token).empty?
        end
      end
    end
  end
end
