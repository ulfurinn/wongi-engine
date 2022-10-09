module Wongi
  module Engine
    OptionalJoinResult = Struct.new :token, :wme do
      def unlink
        wme.opt_join_results.delete self
        token.opt_join_results.delete self
      end
    end

    class OptionalNode < BetaNode
      attr_reader :alpha, :tests, :assignment_pattern

      def initialize(parent, alpha, tests, assignments)
        super(parent)
        @alpha = alpha
        @tests = tests
        @assignment_pattern = assignments
      end

      def make_opt_result(token, wme)
        jr = OptionalJoinResult.new token, wme
        token.opt_join_results << jr
        wme.opt_join_results << jr
      end

      def alpha_activate(wme, children: self.children)
        assignments = collect_assignments(wme)
        tokens.each do |token|
          next unless matches? token, wme

          children.each do |child|
            if token.optional?
              token.no_optional!
              child.tokens.each do |ct|
                child.beta_deactivate(ct) if ct.parent == token
              end
            end
            child.beta_activate Token.new(child, token, wme, assignments)
          end
          make_opt_result token, wme
        end
      end

      def alpha_deactivate(wme)
        wme.opt_join_results.dup.each do |ojr|
          tokens.each do |token|
            next unless token == ojr.token

            ojr.unlink
            next unless token.opt_join_results.empty?

            children.each do |child|
              child.tokens.each do |ct|
                child.beta_deactivate(ct) if ct.parent == token
              end
              token.optional!
              child.beta_activate Token.new(child, token, nil, {})
            end
          end
        end
      end

      def beta_activate(token)
        return if tokens.find { |t| t.duplicate? token }

        overlay.add_token(token)
        match = false
        select_wmes(alpha.template).each do |wme|
          assignments = collect_assignments(wme)
          next unless matches? token, wme

          match = true
          children.each do |child|
            child.beta_activate Token.new(child, token, wme, assignments)
          end
          make_opt_result token, wme
        end
        return if match

        token.optional!
        children.each do |child|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end

      def beta_deactivate(token)
        overlay.remove_token(token)
        beta_deactivate_children(token:)
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate(Token.new(child, token, nil, {}))
        end
        select_wmes(alpha.template).each do |wme|
          alpha_activate wme, children: [child]
        end
      end

      private

      def matches?(token, wme)
        @tests.each do |test|
          return false unless test.matches?(token, wme)
        end
        true
      end

      def collect_assignments(wme)
        assignments = {}
        return assignments if assignment_pattern.nil?

        assignments[assignment_pattern.subject] = TokenAssignment.new(wme, :subject) if assignment_pattern.subject != :_
        assignments[assignment_pattern.predicate] = TokenAssignment.new(wme, :predicate) if assignment_pattern.predicate != :_
        assignments[assignment_pattern.object] = TokenAssignment.new(wme, :object) if assignment_pattern.object != :_
        assignments
      end
    end
  end
end
