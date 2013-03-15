module Wongi
  module Engine

    NegJoinResult = Struct.new :owner, :wme

    class NegNode < BetaNode

      attr_reader :tokens, :alpha, :tests

      def initialize parent, tests, alpha
        super(parent)
        @tests, @alpha = tests, alpha
        @tokens = []
      end

      def alpha_activate wme
        self.tokens.each do |token|
          if matches?( token, wme )
            token.delete_children if token.neg_join_results.empty?
            make_join_result(token, wme)
          end
        end
      end

      def beta_activate token, newwme, assignments
        t = Token.new token, newwme, assignments
        t.node = self
        self.tokens << t
        @alpha.wmes.each do |wme|
          if matches?( t, wme )
            make_join_result(t, wme)
          end
        end
        if t.neg_join_results.empty?
          self.children.each do |child|
            child.beta_activate t, nil, {}
          end
        end
      end

      def refresh_child child
        safe_tokens.each do |token|
          if token.neg_join_results.empty?
            child.beta_activate token, nil, {}
          end
        end
        alpha.wmes.each do |wme|
          alpha_activate wme
        end
      end

      def delete_token token
        tokens.delete token
        token.neg_join_results.each do |njr|
          njr.wme.neg_join_results.delete njr if njr.wme
        end
        token.neg_join_results.clear
      end

      protected

      def matches? token, wme
        puts "matching #{wme} against #{token}" if debug?
        @tests.each do |test|
          return false unless test.matches?( token, wme )
        end
        true
      end

      def make_join_result token, wme
        njr = NegJoinResult.new token, wme
        token.neg_join_results << njr
        wme.neg_join_results << njr
      end

      def safe_tokens
        Enumerator.new do |y|
          @tokens.dup.each do |token|
            y << token unless token.deleted?
          end
        end
      end

    end
  end
end
