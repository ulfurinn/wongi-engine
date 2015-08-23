module Wongi
  module Engine

    TokenAssignment = Struct.new(:wme, :field) do
      def call token = nil
        wme.send field
      end
      def inspect
        "#{field} of #{wme}"
      end
      def to_s
        inspect
      end
    end

    class BetaTest

      attr_reader :field
      attr_reader :variable

      def initialize field, variable
        @field, @variable = field, variable
      end

      def matches? token, wme
        assignment = token[ self.variable ]
        field = wme.send( self.field )
        #field.nil? ||
        assignment && field == assignment
      end

      def equivalent? other
        other.field == self.field && other.variable == self.variable
      end

    end

    class JoinNode < BetaNode

      attr_accessor :alpha
      attr_reader :tests
      attr_reader :assignment_pattern

      def initialize parent, tests, assignment
        super(parent)
        @tests = tests
        @assignment_pattern = assignment
      end

      def equivalent? alpha, tests, assignment_pattern
        return false unless self.alpha == alpha
        return false unless self.assignment_pattern == assignment_pattern
        return false unless (self.tests.empty? && tests.empty?) || self.tests.length == tests.length && self.tests.all? { |my_test|
          tests.any? { |new_test|
            my_test.equivalent? new_test
          }
        }
        true
      end

      def alpha_activate wme
        assignments = collect_assignments( wme )
        parent.tokens.each do |token|
          if matches?( token, wme )
            children.each do |beta|
              beta.beta_activate Token.new( beta, token, wme, assignments )
            end
          end
        end
      end

      def alpha_deactivate wme
        children.each do |child|
          child.tokens.each do |token|
            if token.wme == wme
              child.beta_deactivate token
            end
          end
        end
      end

      def beta_activate token
        self.alpha.wmes.each do |wme|
          if matches?( token, wme )
            assignments = collect_assignments( wme )
            children.each do |beta|
              beta.beta_activate Token.new( beta, token, wme, assignments )
            end
          end
        end
      end

      def beta_deactivate token
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
            end
          end
        end
      end

      def refresh_child child
        alpha.wmes.each do |wme|
          assignments = collect_assignments( wme )
          parent.tokens.each do |token|
            if matches?( token, wme )
              child.beta_activate Token.new( child, token, wme, assignments )
            end
          end
        end
      end

      protected

      def matches? token, wme
        @tests.each do |test|
          return false unless test.matches?( token, wme )
        end
        true
      end

      def collect_assignments wme
        assignments = {}
        return assignments if assignment_pattern.nil?
        if assignment_pattern.subject != :_
          assignments[ assignment_pattern.subject ] = TokenAssignment.new(wme, :subject)
        end
        if assignment_pattern.predicate != :_
          assignments[ assignment_pattern.predicate ] = TokenAssignment.new(wme, :predicate)
        end
        if assignment_pattern.object != :_
          assignments[ assignment_pattern.object ] = TokenAssignment.new(wme, :object)
        end
        assignments
      end

    end
  end
end
