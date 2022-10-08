module Wongi
  module Engine


    class BetaTest
      attr_reader :field, :variable

      def initialize(field, variable)
        @field = field
        @variable = variable
      end

      def matches?(token, wme)
        assignment = token[variable]
        field = wme.send(self.field)
        # field.nil? ||
        !token.has_var?(variable) || field == assignment
      end

      def equivalent?(other)
        other.field == field && other.variable == variable
      end
    end

    class JoinNode < BetaNode
      attr_accessor :alpha
      attr_reader :tests, :assignment_pattern

      def initialize(parent, tests, assignment)
        super(parent)
        @tests = tests
        @assignment_pattern = assignment
      end

      def equivalent?(alpha, tests, assignment_pattern)
        return false unless self.alpha == alpha
        return false unless self.assignment_pattern == assignment_pattern
        return false unless (self.tests.empty? && tests.empty?) || (self.tests.length == tests.length && self.tests.all? { |my_test|
          tests.any? { |new_test|
            my_test.equivalent? new_test
          }
        })

        true
      end

      def alpha_activate(wme)
        assignments = collect_assignments(wme)

        tokens.each do |token|
          next unless matches?(token, wme)

          children.each do |beta|
            beta.beta_activate Token.new(beta, token, wme, assignments)
          end
        end
      end

      def alpha_deactivate(wme)
        beta_deactivate_children(wme:)
      end

      def beta_activate(token)
        overlay.add_token(token)

        select_wmes(alpha.template).each do |wme|
          next unless matches?(token, wme)

          assignments = collect_assignments(wme)
          children.each do |beta|
            beta.beta_activate Token.new(beta, token, wme, assignments)
          end
        end
      end

      def beta_deactivate(token)
        overlay.remove_token(token)
        beta_deactivate_children(token:)
      end

      def refresh_child(child)
        select_wmes(alpha.template).each do |wme|
          assignments = collect_assignments(wme)
          tokens.each do |token|
            child.beta_activate Token.new(child, token, wme, assignments) if matches?(token, wme)
          end
        end
      end

      protected

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
