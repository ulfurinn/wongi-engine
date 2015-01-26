module Wongi::Engine

  class UndefinedBaseRule < StandardError
    def initialize rule_name
      @rule_name = rule_name
    end

    def message
      "undefined production #@rule_name"
    end
  end

  class AssumingClause

    attr_reader :base_rule_name
    attr_reader :base_production

    def initialize base_rule_name, base_production = nil
      @base_rule_name = base_rule_name
      @base_production = base_production
    end

    def import_into engine
      base_production = engine.productions[ base_rule_name ]
      raise UndefinedBaseRule.new(base_rule_name) unless base_production
      self.class.new base_rule_name, base_production
    end

    def compile context
      raise DefinitionError.new("'assuming' cannot be preceded by other matchers") unless context.earlier.empty?
      raise StandardError.new("missing base context") unless base_production.parent.context
      base_production.parent.context.dup
    end

  end

end
