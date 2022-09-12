module Wongi
  module Engine
    class Ruleset
      class << self
        def [](name)
          raise Error, "undefined ruleset #{name}" unless rulesets.key?(name)

          rulesets[name]
        end

        def register(name, ruleset)
          raise Error, "ruleset #{name} already exists" if rulesets.key?(name)

          rulesets[name] = ruleset
        end

        def rulesets
          @rulesets ||= {}
        end

        def reset
          @rulesets = {}
        end
      end

      def initialize(name = nil)
        @rules = []
        self.name(name) if name
      end

      def inspect
        "<Ruleset #{name}>"
      end

      def install(rete)
        # puts "Installing ruleset #{name}"
        @rules.each { |rule| rete << rule }
      rescue StandardError => e
        e1 = Error.new "error installing ruleset '#{name || '<unnamed>'}': #{e}"
        e1.set_backtrace e.backtrace
        raise e1
      end

      def name(name = nil)
        if name && !@name
          self.class.register name, self
          @name = name
        end
        @name
      end

      #    def uri uri = nil
      #      @uri = uri if uri
      #      @uri
      #    end

      def rule(name, &definition)
        r = DSL::Rule.new name
        r.instance_eval(&definition)
        @rules << r
        r
      end

      def query(name, &definition)
        r = DSL::Query.new name
        r.instance_eval(&definition)
        @rules << r
        r
      end
    end
  end
end
