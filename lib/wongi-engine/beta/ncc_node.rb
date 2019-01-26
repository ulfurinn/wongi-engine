module Wongi
  module Engine
    class NccNode < BetaNode
      include TokenContainer

      attr_accessor :partner

      def initialize parent
        super
      end

      def beta_activate token
        return if tokens.find { |t| t.parent == token }
        t = Token.new self, token, nil, {}
        t.overlay.add_token(t, self)
        partner.tokens.each do |ncc_token|
          next unless ncc_token.ancestors.find { |a| a.equal? token }
          t.ncc_results << ncc_token
          ncc_token.owner = t
        end
        if t.ncc_results.empty?
          children.each do |child|
            child.beta_activate Token.new( child, t, nil, { } )
          end
        end
      end

      def beta_deactivate token
        t = tokens.find { |tok| tok.parent == token }
        return unless t
        t.overlay.remove_token(t, self)
        t.deleted!
        partner.tokens.select { |ncc| ncc.owner == t }.each do |ncc_token|
          ncc_token.owner = nil
          t.ncc_results.delete ncc_token
        end
        children.each do |beta|
          beta.tokens.select { |token| token.parent == t }.each do |token|
            beta.beta_deactivate token
          end
        end
      end

      def ncc_activate token
        children.each do |child|
          child.beta_activate Token.new( child, token, nil, { } )
        end
      end

      def ncc_deactivate token
        children.each do |beta|
          beta.tokens.select { |t| t.parent == token }.each do |t|
            beta.beta_deactivate t
          end
        end
      end

      def refresh_child child
        tokens.each do |token|
          if token.ncc_results.empty?
            child.beta_activate Token.new( child, token, nil, { } )
          end
        end
      end
    end
  end
end
