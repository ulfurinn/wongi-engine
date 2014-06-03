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
      attr_reader :filters

      def initialize parent, tests, assignment, filters
        super(parent)
        @tests = tests
        @assignment_pattern = assignment
        @filters = filters
      end

      def equivalent? alpha, tests, assignment_pattern, filters
        return false unless self.alpha == alpha
        return false unless self.assignment_pattern == assignment_pattern
        return false unless (self.tests.empty? && tests.empty?) || self.tests.length == tests.length && self.tests.all? { |my_test|
          tests.any? { |new_test|
            my_test.equivalent? new_test
          }
        }
        return false unless (self.filters.empty? && filters.empty?) || self.filters.length == filters.length && self.filters.all? { |my_filter|
          filters.include? my_filter
        }
        true
      end

      def alpha= a
        @alpha = a
        # puts "\talpha = #{alpha}"
      end

      def alpha_activate wme
        dp "JOIN alpha-activated with #{wme}"
        collected = collect_assignments( wme )
        self.parent.tokens.each do |token|
          dp "-MATCHING #{token}"
          if matches?( token, wme ) && passes_filters?( token, wme, collected )
            dp "-JOIN MATCHED, PROPAGATING"
            propagate_activation token, wme, collected
          end
        end
      end

      def beta_activate token
        dp "JOIN beta-activated"
        self.alpha.wmes.each do |wme|
          dp "-TESTING WME #{wme}"
          collected = collect_assignments( wme )
          if matches?( token, wme ) && passes_filters?( token, wme, collected )
            dp "-WME MATCHED, PROPAGATING"
            propagate_activation token, wme, collected
          else
            dp "-NO MATCH"
          end
        end
      end

      def refresh_child child
        tmp = children
        self.children = [ child ]
        alpha.wmes.each do |wme|
          alpha_activate wme
        end
        self.children = tmp
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

      def passes_filters? token, wme, assignments
        t = FakeToken.new token, wme, assignments
        @filters.all? { |filter| filter.passes? t }
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
