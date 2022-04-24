module Wongi::Engine::DSL
  class Builder

    def initialize
      @current_section = nil
      @current_clause = nil
      @clauses = []
    end

    def build(&definition)
      instance_eval &definition
      @clauses.each do |c|
        Wongi::Engine::DSL.sections[c[:section]] ||= Class.new do
          include Generated
        end
        Wongi::Engine::DSL.sections[c[:section]].create_dsl_method(c)
      end
    end

    def section(s)
      @current_section = s
    end

    def clause(*c)
      @current_clause = c
    end

    def action(klass = nil, &block)
      raise DefinitionError, "Cannot create an action without a clause" if @current_clause.nil?
      @clauses << { section: @current_section, clause: @current_clause, action: klass || block }
      @current_clause = nil
    end

    def body(klass = nil, &block)
      raise DefinitionError, "Cannot create a body without a clause" if @current_clause.nil?
      @clauses << { section: @current_section, clause: @current_clause, body: klass || block }
      @current_clause = nil
    end

    def accept(klass)
      raise DefinitionError, "Cannot create an acceptor without a clause" if @current_clause.nil?
      @clauses << { section: @current_section, clause: @current_clause, accept: klass }
      @current_clause = nil
    end

  end
end
