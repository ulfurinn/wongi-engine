module Wongi
  module Engine
    NegJoinResult = Struct.new :token, :wme, :neg_node do
      def unlink
        wme.neg_join_results.delete self
        token.neg_join_results.delete self
      end
    end

    class NegNode < BetaNode
      attr_reader :alpha, :tests

      def initialize(parent, tests, alpha, unsafe)
        super(parent)
        @tests = tests
        @alpha = alpha
        @unsafe = unsafe
      end

      def alpha_activate(wme, children: self.children)
        # p alpha_activate: {class: self.class, object_id:, wme:}
        tokens.each do |token|
          next unless matches?(token, wme) && (@unsafe || !token.generated?(wme)) # feedback loop protection

          # order matters for proper invalidation
          make_join_result(token, wme)
          beta_deactivate_children(token:, children:)
        end
      end

      def alpha_deactivate(wme)
        # p alpha_deactivate: {class: self.class, object_id:, wme:}
        wme.neg_join_results.dup.each do |njr|
          tokens.each do |token|
            next unless token == njr.token

            njr.unlink
            next unless token.neg_join_results.empty?

            children.each do |child|
              child.beta_activate(Token.new(child, token, nil))
            end
          end
        end
      end

      def beta_activate(token)
        # p beta_activate: {class: self.class, object_id:, token:}
        return if tokens.find { |t| t.duplicate? token }

        overlay.add_token(token)
        select_wmes(alpha.template).each do |wme|
          make_join_result(token, wme) if matches?(token, wme)
        end
        return if token.neg_join_results.any?

        children.each do |child|
          child.beta_activate(Token.new(child, token, nil, {}))
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)
        beta_deactivate_children(token:)
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate(Token.new(child, token, nil, {})) if token.neg_join_results.empty?
        end
        select_wmes(alpha.template).each do |wme|
          alpha_activate wme, children: [child]
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
        njr = NegJoinResult.new token, wme, self
        token.neg_join_results << njr
        wme.neg_join_results << njr
      end
    end
  end
end
