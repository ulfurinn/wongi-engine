module Wongi::Engine
  class TraceAction < Action

    attr_accessor :production

    class DefaultTracer
      class << self
        def trace args
          case args[:action]
          when TraceAction
            if args[:token]
              puts "EXECUTED RULE #{args[:action].rule.name} WITH #{args[:token]}"
            else
              puts "EXECUTED RULE #{args[:action].rule.name}"
            end
          when StatementGenerator
            puts "GENERATED #{args[:wme]}"
          end
        end
      end
    end

    class << self
      attr_writer :production_tracer
      def production_tracer
        @production_tracer || DefaultTracer
      end
    end

    def initialize *opts
      @verbose = false
      @values = false
      opts.each do |opt|
        case opt
        when :verbose
          verbose!
        when :silent
          silent!
        when :values
          report_values!
        end
      end
    end

    def verbose!
      @verbose = true
    end

    def silent!
      @verbose = false
    end

    def report_values!
      @values = true
    end

    def trace args
      self.class.production_tracer.trace args
    end

    def execute token
      production.tracer = self
      if @values
        trace action: self, token: token
      else
        trace action: self
      end
    end
  end


end

dsl {
  section :make
  clause :trace
  action Wongi::Engine::TraceAction
}
