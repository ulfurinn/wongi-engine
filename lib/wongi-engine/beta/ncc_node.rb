module Wongi
  module Engine
    class NccSet

      attr_reader :children
      def initialize conditions
        @children = conditions
      end

      def compile context
        context.node = context.node.beta_memory.ncc_node( self, context.earlier, context.parameters, false )
        context.node.context = context
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

      def beta_activate token
        return if @tokens.find { |t| t.parent == token }
        t = Token.new self, token, nil, {}
        @tokens << t
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
        t = @tokens.find { |tok| tok.parent == token }
        return unless @tokens.delete t
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
        token.deleted = false
        @tokens << token unless @tokens.include?( token )
        children.each do |child|
          child.beta_activate Token.new( child, token, nil, { } )
        end
      end

      def ncc_deactivate token
        return unless @tokens.delete token
        token.deleted!
        children.each do |beta|
          beta.tokens.select { |t| t.parent == token }.each do |t|
            beta.beta_deactivate t
          end
        end
      end

      def refresh_child child
        tokens.each do |token|
          if token.ncc_results.empty?
            child.beta_activate Token.new( child, t, nil, { } )
          end
        end
      end

      # def delete_token token
      #   tokens.delete token
      #   token.ncc_results.each do |nccr|
      #     nccr.wme.tokens.delete( nccr ) if nccr.wme
      #     nccr.parent.children.delete nccr
      #   end
      #   token.ncc_results.clear
      # end

    end
  end
end
