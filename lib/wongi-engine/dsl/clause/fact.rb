module Wongi::Engine
  module DSL::Clause
    Has = Struct.new(:subject, :predicate, :object) do
      include CoreExt
      attr_predicate :debug

      def initialize(s, p, o, options = {})
        debug! if options[:debug]
        super(s, p, o)
      end

      def compile(context)
        tests, assignment = parse_variables(context)
        context.tap { |c| c.join_node(self, tests, assignment) }
      end

      def inspect
        "<+#{subject.inspect} #{predicate.inspect} #{object.inspect}>"
      end

      private

      def parse_variables(context)
        tests = []
        assignment_mapping = %i[subject predicate object].map do |member|
          value = send(member)
          if Template.variable?(value)
            if context.declares_variable?(value)
              tests << BetaTest.new(member, value)
              :_
            else
              value
            end
          else
            :_
          end
        end
        assignment = Template.new(*assignment_mapping)
        assignment.variables.each { |v| context.declare(v) }
        [tests, assignment]
      end
    end

    class Neg < Has
      def compile(context)
        tests, assignment = parse_variables(context)
        raise DefinitionError, "Negative matches may not introduce new variables: #{assignment.variables}" unless assignment.root?

        context.tap { |c| c.neg_node(self, tests) }
      end

      def inspect
        "<-#{subject.inspect} #{predicate.inspect} #{object.inspect}>"
      end
    end

    class Opt < Has
      def compile(context)
        tests, assignment = parse_variables(context)
        context.tap { |c| c.opt_node(self, tests, assignment) }
      end

      def inspect
        "<?#{subject.inspect} #{predicate.inspect} #{object.inspect}>"
      end
    end
  end
end
