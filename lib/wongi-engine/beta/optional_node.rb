module Wongi
  module Engine

    OptionalJoinResult = Struct.new :token, :wme do
      def unlink
        wme.opt_join_results.delete self
        token.opt_join_results.delete self
      end
    end

    class OptionalNode < BetaNode
      include TokenContainer

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

      def alpha_activate(wme)
        assignments = collect_assignments(wme)
        tokens.each do |token|
          if matches? token, wme
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
      end

      def alpha_deactivate(wme)
        wme.opt_join_results.dup.each do |ojr|
          tokens.each do |token|
            next unless token == ojr.token
            ojr.unlink
            if token.opt_join_results.empty?
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
      end

      def beta_activate(t)
        return if tokens.find { |token| token.parent == t }
        token = Token.new(self, t, nil, {})
        token.overlay.add_token(token, self)
        match = false
        alpha.wmes.each do |wme|
          assignments = collect_assignments(wme)
          if matches? token, wme
            match = true
            children.each do |child|
              child.beta_activate Token.new(child, token, wme, assignments)
            end
            make_opt_result token, wme
          end
        end
        unless match
          token.optional!
          children.each do |child|
            child.beta_activate Token.new(child, token, nil, {})
          end
        end
      end

      def beta_deactivate(t)
        token = tokens.find { |token| token.parent == t }
        return unless token
        token.overlay.remove_token(token, self)
        token.deleted!
        if token.parent
          token.parent.children.delete token
        end
        token.opt_join_results.each &:unlink
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
            end
          end
        end
        token
      end

      def refresh_child(child)
        tmp = children
        self.children = [child]
        refresh # do the beta part
        alpha.wmes.each do |wme|
          alpha_activate wme
        end
        self.children = tmp
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
        if assignment_pattern.subject != :_
          assignments[assignment_pattern.subject] = TokenAssignment.new(wme, :subject)
        end
        if assignment_pattern.predicate != :_
          assignments[assignment_pattern.predicate] = TokenAssignment.new(wme, :predicate)
        end
        if assignment_pattern.object != :_
          assignments[assignment_pattern.object] = TokenAssignment.new(wme, :object)
        end
        assignments
      end
    end
  end
end
