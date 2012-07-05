module Wongi
  module Engine
    class NegTemplate < Template
      # :arg: context => Wongi::Rete::BetaNode::CompilationContext
      def compile context
        tests, _ = *JoinNode.compile( self, context.earlier, context.parameters )
        alpha = context.rete.compile_alpha( self )
        context.node = context.node.neg_node( alpha, tests, context.alpha_deaf )
        context.node.debug = debug?
        context.earlier << self
        context
      end
    end

    NegJoinResult = Struct.new :owner, :wme

    class NegNode < BetaNode

      attr_reader :tokens, :alpha, :tests

      def initialize parent, tests, alpha
        super(parent)
        @tests, @alpha = tests, alpha
        @tokens = []
      end

      def right_activate wme
        self.tokens.each do |token|
          if matches?( token, wme )
            token.delete_children if token.neg_join_results.empty?
            make_join_result(token, wme)
          end
        end
      end

      def left_activate token, newwme, assignments
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
            child.left_activate t, nil, {}
          end
        end
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
    end
  end
end
