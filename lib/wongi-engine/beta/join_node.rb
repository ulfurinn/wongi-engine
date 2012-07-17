module Wongi
  module Engine

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
        return false unless (self.tests.empty? && tests.empty?) || self.tests.all? { |my_test|
          tests.any? { |new_test|
            my_test.equivalent? new_test
          }
        }
        true
      end

      def alpha= a
        @alpha = a
        # puts "\talpha = #{alpha}"
      end

      def right_activate wme
        ws = '  ' * depth
        # puts "#{ws}JOIN #{@id} right-activated with #{wme}"
        collected = collect_assignments( wme )
        # puts "PARENT HAS #{parent.tokens.length} TOKENS"
        self.parent.tokens.each do |token|
          # puts "#{ws}matching with token"
          if matches?( token, wme )
            # puts "#{ws}JOIN RIGHT-MATCHED, PROPAGATING"
            propagate_activation token, wme, collected
          end
        end
      end

      def left_activate token
        ws = '  ' * depth
        self.alpha.wmes.uniq.each do |wme|
          if matches?( token, wme )
            propagate_activation token, wme, collect_assignments( wme )
          end
        end
      end

      def refresh_child child
        tmp = children
        self.children = [ child ]
        alpha.wmes.each do |wme|
          right_activate wme
        end
        self.children = tmp
      end

      def self.compile condition, earlier, parameters
        tests = []
        assignment = Template.new
        [:subject, :predicate, :object].each do |field|
          member = condition.send field
          if Template.variable?( member )

            contains = parameters.include? member
            if earlier.any? do |ec|
                ! ec.kind_of?( NegTemplate ) and ec.contains?( member )
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
            assignments[ self.assignment_pattern.send(field) ] = wme.send(field)
          end
        end
        assignments
      end

    end
  end
end
