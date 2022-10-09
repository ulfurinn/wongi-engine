module Wongi::Engine
  class AggregateNode < BetaNode
    attr_reader :alpha, :tests, :assignment_pattern, :map, :function, :assign

    def initialize(parent, alpha, tests, assignment, map, function, assign)
      super(parent)
      @alpha = alpha
      @tests = tests
      @assignment_pattern = assignment
      @map = map
      @function = function
      @assign = assign
    end

    def equivalent?(alpha, tests, assignment_pattern)
      return false if self.alpha != alpha
      return false if self.assignment_pattern != assignment_pattern
      return true if self.tests.empty? && tests.empty?
      return false if self.tests.length != tests.length

      self.tests.all? { |my_test|
        tests.any? { |new_test|
          my_test.equivalent? new_test
        }
      }
    end

    def alpha_activate(wme)
      # we need to re-run all WMEs through the aggregator, so the new incoming one doesn't matter
      tokens.each do |token|
        evaluate(wme:, token:)
      end
    end

    def alpha_deactivate(wme)
      # we need to re-run all WMEs through the aggregator, so the new incoming one doesn't matter
      tokens.each do |token|
        evaluate(wme:, token:)
      end
    end

    def beta_activate(token)
      return if tokens.find { |t| t.duplicate? token }

      overlay.add_token(token)
      evaluate(wme: nil, token:)
    end

    def beta_deactivate(token)
      overlay.remove_token(token)
      beta_deactivate_children(token:)
    end

    def refresh_child(child)
      tokens.each do |token|
        evaluate(wme: nil, token:, child:)
      end
    end

    def evaluate(wme:, token:, child: nil)
      # clean up previous decisions
      # # TODO: optimise: only clean up if the value changed
      beta_deactivate_children(token:)

      candidates = select_wmes(alpha.template) { |asserted_wme| matches?(token, asserted_wme) }

      return if candidates.empty?

      mapped = candidates.map(&map)
      value = if function.is_a?(Symbol) && mapped.respond_to?(function)
                mapped.send(function)
              else
                function.call(mapped)
              end
      assignments = { assign => value }
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
  end
end
