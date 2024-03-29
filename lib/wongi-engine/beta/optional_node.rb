module Wongi
  module Engine
    OptionalJoinResult = Struct.new :token, :wme

    class OptionalNode < BetaNode
      attr_reader :alpha, :tests, :assignment_pattern

      def initialize(parent, alpha, tests, assignments)
        super(parent)
        @alpha = alpha
        @tests = tests
        @assignment_pattern = assignments
      end

      def alpha_activate(wme, children: self.children)
        assignments = collect_assignments(wme)
        tokens.each do |token|
          next if token.ancestral_wme?(wme)
          next unless matches? token, wme

          optional = overlay.opt_join_results_for(token: token).empty?

          children.each do |child|
            if optional
              # we're going to change the optional state so the old ones need to be removed
              child.tokens.each do |ct|
                child.beta_deactivate(ct) if ct.child_of?(token)
              end
            end
            child.beta_activate Token.new(child, token, wme, assignments)
          end
          overlay.add_opt_join_result(OptionalJoinResult.new(token, wme))
        end
      end

      def alpha_deactivate(wme)
        # p alpha_deactivate: {wme:}
        overlay.opt_join_results_for(wme: wme).each do |ojr|
          tokens.each do |token|
            next unless token == ojr.token

            overlay.remove_opt_join_result(ojr)
            next unless overlay.opt_join_results_for(token: token).empty?

            children.each do |child|
              child.tokens.each do |ct|
                child.beta_deactivate(ct) if ct.child_of?(token)
              end
              child.beta_activate Token.new(child, token, nil, {})
            end
          end
        end
      end

      def beta_activate(token)
        overlay.add_token(token)

        match = false
        template = specialize(alpha.template, tests, token)
        select_wmes(template).each do |wme|
          assignments = collect_assignments(wme)
          next unless matches? token, wme

          match = true
          children.each do |child|
            child.beta_activate Token.new(child, token, wme, assignments)
          end
          make_opt_result token, wme
        end
        return if match

        children.each do |child|
          child.beta_activate Token.new(child, token, nil, {})
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)
        beta_deactivate_children(token: token)
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
