module Wongi::Engine
  class DSLBuilder

    def initialize
      @current_section = nil
      @current_clause = nil
      @clauses = []
    end

    def build &definition
      instance_eval &definition
      @clauses.each do |c|
        DSLExtensions.create_extension c
      end
    end
    
    def section s
      @current_section = s
    end
    
    def clause *c
      @current_clause = c
    end
    
    def action klass = nil, &block
      raise "Cannot create an action without a clause" if @current_clause.nil?
      @clauses << { :section => @current_section, :clause => @current_clause, :action => klass || block }
      @current_clause = nil
    end

    def body klass = nil, &block
      raise "Cannot create a body without a clause" if @current_clause.nil?
      @clauses << { :section => @current_section, :clause => @current_clause, :body => klass || block }
      @current_clause = nil
    end

    def accept klass = nil, &block
      raise "Cannot create an acceptor without a clause" if @current_clause.nil?
      @clauses << { :section => @current_section, :clause => @current_clause, :accept => klass || block }
      @current_clause = nil
    end

  end
end
