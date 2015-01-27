module Wongi
  module Engine

    TokenAssignment = Struct.new(:wme, :field) do
      def call token = nil
        wme.send field
      end
      def inspect
        "subject of #{wme}"
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
              #token.destroy
            end
          end
        end
      end

      def beta_activate token
        dp "JOIN beta-activated"
        self.alpha.wmes.each do |wme|
          dp "-TESTING WME #{wme}"
          assignments = collect_assignments( wme )
          if matches?( token, wme )
            dp "-WME MATCHED, PROPAGATING"
            children.each do |beta|
              beta.beta_activate Token.new( beta, token, wme, assignments )
            end
          else
            dp "-NO MATCH"
          end
        end
      end

      def beta_deactivate token
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
              #token.destroy
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

      def self.compile condition, earlier, parameters
        tests = []
        assignment = Template.new :_, :_, :_
        [:subject, :predicate, :object].each do |field|
          member = condition.send field
          if Template.variable?( member )

            contains = parameters.include? member
            if earlier.any? do |ec|
                if ec.kind_of?( VariantSet )
                  ec.introduces_variable?( member )
                else
                  ec.respond_to?( :contains? ) and ec.contains?( member )
                end
              end
              contains = true
            end

            if contains
              tests << BetaTest.new( field, member )
            else
              method = (field.to_s + "=").to_sym
              assignment.send method, member
            end

          end
        end
        return tests, assignment
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
        return assignments if self.assignment_pattern.nil?
        # puts "more assignments"
        [:subject, :predicate, :object].each do |field|
          if self.assignment_pattern.send(field) != :_
            #puts "#{self.assignment_pattern.send(field)} = #{wme.send(field)}"
            assignments[ self.assignment_pattern.send(field) ] = TokenAssignment.new( wme, field )
          end
        end
        assignments
      end

    end
  end
end
