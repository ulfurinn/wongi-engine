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

      def beta_activate token
        t = Token.new self, token, nil, {}
        owner = owner_for( t )
        tokens << t
        if owner
          owner.ncc_results << t
          t.owner = owner
          owner.node.ncc_deactivate owner
        end
      end

      def beta_deactivate t
        token = tokens.find { |tok| tok.parent == t }
        return unless token
        token.owner.ncc_results.delete token
        if token.owner.ncc_results.empty?
          ncc.ncc_activate token.owner
        end
      end

      private

      def owner_for token
        divergent_token = token.ancestors.find { |t| t.node == divergent }
        ncc.tokens.find { |t| t.ancestors.include? divergent_token }
      end

      # def delete_token token
      #   token.owner.ncc_results.delete token
      #   if token.owner.ncc_results.empty?
      #     ncc.children.each do |node|
      #       node.beta_activate token.owner, nil, {}
      #     end
      #   end

      # end
    end
  end
end
