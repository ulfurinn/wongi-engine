module Wongi::Engine
  class AggregateNode < BetaNode
    attr_reader :alpha
    attr_reader :tests
    attr_reader :assignment_pattern
    attr_reader :member
    attr_reader :function

    def initialize(parent, alpha, tests, assignment, member, function)
      super(parent)
      @alpha = alpha
      @tests = tests
      @assignment_pattern = assignment
      @member = member
      @function = function
    end

    def equivalent?(alpha, tests, assignment_pattern)
      return false unless self.alpha == alpha
      return false unless self.assignment_pattern == assignment_pattern
      return false unless (self.tests.empty? && tests.empty?) || self.tests.length == tests.length && self.tests.all? { |my_test|
        tests.any? { |new_test|
          my_test.equivalent? new_test
        }
      }
      true
    end

    def alpha_activate(_)
      # we need to re-run all WMEs through the aggregator, so the new incoming one doesn't matter
      parent.tokens.each do |token|
        evaluate(token)
      end
    end

    def alpha_deactivate(_)
      # we need to re-run all WMEs through the aggregator, so the new incoming one doesn't matter
      parent.tokens.each do |token|
        evaluate(token)
      end
    end

    def beta_activate(token)
      evaluate(token)
    end

    def beta_deactivate(token)
      children.each do |child|
        child.tokens.each do |t|
          if t.parent == token
            child.beta_deactivate t
          end
        end
      end
    end

    def refresh_child(child)
      parent.tokens.each do |token|
        evaluate(token, child)
      end
    end

    def evaluate(token, child = nil)
      candidates = alpha.wmes.select { |wme| matches?(token, wme) }

      if candidates.empty?
        # deactivate anything remaining from previous runs
        beta_deactivate(token)
        return
      end

      pivot = candidates.map(&member).send(function)
      wme = candidates.find { |wme| wme.send(member) == pivot }
      assignments = collect_assignments(wme)
      if child
        child.beta_activate(Token.new(child, token, wme, assignments))
      else
        children.each do |beta|
          beta.beta_activate(Token.new(beta, token, wme, assignments))
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
