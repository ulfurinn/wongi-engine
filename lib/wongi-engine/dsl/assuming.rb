module Wongi::Engine
  class UndefinedBaseRule < StandardError
    def initialize(rule_name)
      @rule_name = rule_name
    end

    def message
      "undefined production #{@rule_name}"
    end
  end

  class AssumingClause
    attr_reader :base_rule_name

    def initialize(base_rule_name)
      @base_rule_name = base_rule_name
    end

    def compile(context)
      base_production = context.rete.productions[base_rule_name]
      raise UndefinedBaseRule.new(base_rule_name) unless base_production
      raise DefinitionError.new("'assuming' cannot be preceded by other matchers") unless context.node.root?
      raise StandardError.new("missing base context") unless base_production.compilation_context

      base_production.compilation_context.dup
    end
  end
end
