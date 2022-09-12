module Wongi
  module Engine
    NegJoinResult = Struct.new :token, :wme do
      def unlink
        wme.neg_join_results.delete self
        token.neg_join_results.delete self
      end
    end

    class NegNode < BetaNode
      include TokenContainer

      attr_reader :alpha, :tests

      def initialize(parent, tests, alpha, unsafe)
        super(parent)
        @tests = tests
        @alpha = alpha
        @unsafe = unsafe
      end

      def alpha_activate(wme)
        tokens.each do |token|
          next unless matches?(token, wme) && (@unsafe || !token.generated?(wme)) # feedback loop protection
          # order matters for proper invalidation
          make_join_result(token, wme)
          #token.delete_children #if token.neg_join_results.empty? # TODO why was this check here? it seems to break things
          children.each do |child|
            child.tokens.each do |t|
              if t.parent == token
                child.beta_deactivate t
                #token.destroy
              end
            end
          end
        end
      end

      def alpha_deactivate(wme)
        wme.neg_join_results.dup.each do |njr|
          tokens.each do |token|
            next unless token == njr.token

            njr.unlink
            next unless token.neg_join_results.empty?
            children.each do |child|
              child.beta_activate Token.new(child, token, nil, {})
            end
          end
        end
      end

      def beta_activate(token)
        return if tokens.find { |et| et.duplicate? token }

        token.overlay.add_token(token, self)
        alpha.wmes.each do |wme|
          make_join_result(token, wme) if matches?(token, wme)
        end
        if token.neg_join_results.empty?
          children.each do |child|
            child.beta_activate Token.new(child, token, nil, {})
          end
        end
      end

      def beta_deactivate(token)
        return nil unless tokens.find token

        token.overlay.remove_token(token, self)
        token.deleted!
        if token.parent
          token.parent.children.delete token # should this go into Token#destroy?
        end
        token.neg_join_results.each &:unlink
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
              #token.destroy
            end
          end
        end
        token
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate Token.new(child, token, nil, {}) if token.neg_join_results.empty?
        end
        alpha.wmes.each do |wme|
          alpha_activate wme
        end
      end

      protected

      def matches?(token, wme)
        puts "matching #{wme} against #{token}" if debug?
        @tests.each do |test|
          return false unless test.matches?(token, wme)
        end
        true
      end

      def make_join_result(token, wme)
        njr = NegJoinResult.new token, wme
        token.neg_join_results << njr
        wme.neg_join_results << njr
      end
    end
  end
end
