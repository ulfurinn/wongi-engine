module Wongi
  module Engine
    NegJoinResult = Struct.new :token, :wme

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
          overlay.add_neg_join_result(NegJoinResult.new(token, wme))
          beta_deactivate_children(token: token, children: children)
        end
      end

      def alpha_deactivate(wme)
        # p alpha_deactivate: {class: self.class, object_id:, wme:}
        overlay.neg_join_results_for(wme: wme).each do |njr|
          tokens.each do |token|
            next unless token == njr.token

            overlay.remove_neg_join_result(njr)
            next unless overlay.neg_join_results_for(token: token).empty?

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
          overlay.add_neg_join_result(NegJoinResult.new(token, wme)) if matches?(token, wme)
        end
        return if overlay.neg_join_results_for(token: token).any?

        children.each do |child|
          child.beta_activate(Token.new(child, token, nil, {}))
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)
        beta_deactivate_children(token: token)
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate(Token.new(child, token, nil, {})) if overlay.neg_join_results_for(token: token).empty?
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
    end
  end
end
