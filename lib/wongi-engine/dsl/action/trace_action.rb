module Wongi::Engine
  module DSL::Action
    class TraceAction < Base

      class DefaultTracer
        attr_accessor :action
        def trace args
          case args[:action]
          when TraceAction
            if args[:token]
              action.io.puts "EXECUTED RULE #{args[:action].rule.name} WITH #{args[:token]}"
            else
              action.io.puts "EXECUTED RULE #{args[:action].rule.name}"
            end
          when StatementGenerator
            action.io.puts "GENERATED #{args[:wme]}" if action.generation?
          end
        end
      end

      attr_reader :io
      attr_predicate :generation, :values

      def initialize opts = { }
        [:generation, :values, :tracer, :tracer_class, :io].each do |option|
          if opts.has_key? option
            instance_variable_set "@#{option}", opts[option]
          end
        end
        @io ||= $stdout
        @tracer ||= (@tracer_class || DefaultTracer).new
        @tracer.action = self
      end

      def trace args
        @tracer.trace args
      end

      def execute token
        production.tracer = self
        if values?
          trace action: self, token: token
        else
          trace action: self
        end
      end
    end
  end
end
