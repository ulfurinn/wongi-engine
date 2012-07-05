module Wongi

  module Engine

    module DSLExtensions

      def self.create_extension section, clause, action
        define_method clause do |*args, &block|
          raise "#{clause} can only be used in section #{section}, currently in #{@current_section}" if section != @current_section
          c = ExtensionClause.new *args, &block
          c.name = clause
          c.action = action
          accept c
        end
      end

    end

    class DSLBuilder

      def initialize
        @current_section = nil
        @current_clause = nil
        @clauses = []
      end

      def build &definition
        instance_eval &definition
        @clauses.each do |c|
          DSLExtensions.create_extension c[:section], c[:clause], c[:action]
        end
      end
    
      def section s
        @current_section = s
      end
    
      def clause c
        @current_clause = c
      end
    
      def action klass
        klass.category( @current_clause ) unless klass.category
        @clauses << { :section => @current_section, :clause => @current_clause, :action => klass }
      end

    end

    class Action

      attr_accessor :production
      attr_accessor :model

      def self.category category = nil
        if category
          @category = category
        end
        @category
      end

      def category
        self.class.category
      end

    end

    class SimpleCollector < Action

      def initialize variable, method
        @variable = variable
        (class << self; self; end).instance_eval do
          #        define_method method do
          #          collect variable
          #        end
          alias_method method, :default_collect
        end
      end

      def default_collect
        collect @variable
      end

      def model= model
        super
        model.add_collector self, category
      end

      def collect var
        production.tokens.map { |token| token[var] }
      end

    end

    class GenerationClause

      def initialize triple
        @triple = triple
      end

      def import_into model
        generator = StatementGenerator.new @triple.import_into( model )
        generator.model = model
        generator
      end

    end

    class ExtensionClause

      attr_accessor :name, :action

      def initialize *args, &block
        @args = args
        @block = block
      end

      def import_into model
        a = action.new *@args, &@block
        a.model = model
        a
      rescue Exception => e
        e1 = Exception.new "error defining clause #{name} handled by #{action}: #{e}"
        e1.set_backtrace e.backtrace
        raise e1
      end

    end

    class GenericProductionRule

      attr_reader :name
      attr_reader :conditions, :actions

      include DSLExtensions

      class << self

        def section s
          unless sections.include?(s)
            sections << s
            define_method s do |&d|
              @current_section = s
              instance_eval &d
            end
          end
        end
      
        def sections
          @sections ||= []
        end

      end

      section :forall
      section :make

      def initialize name
        @name = name
        @conditions = []
        @actions = []
        @current_section = nil
        @acceptors = {}
        GenericProductionRule.sections.each { |section| @acceptors[section] ||= [] }
      end

      def import_into model

        copy = self.class.new @name

        copy.conditions = @acceptors[:forall].map do |condition|
          if condition.respond_to? :import_into
            condition.import_into(model)
          else
            condition
          end
        end

        copy.actions = @acceptors[:make].map do |action|
          if action.respond_to? :import_into
            action.import_into(model)
          else
            action
          end
        end

        copy
      rescue Exception => e
        e1 = Exception.new "in rule #{name}: #{e}"
        e1.set_backtrace e.backtrace
        raise e1
      end

      protected
      attr_writer :conditions, :actions

      def accept stuff
        @acceptors[@current_section] << stuff
      end

      def has s, p, o, time = 0
        accept Template.new( s, p, o, time )
      end

      def missing s, p, o, time = 0
        condition = NegTriple.new( s, p, o, time )
        accept condition
        condition
      end
      alias_method :neg, :missing

      def none &subnet
        sub = NccProductionRule.new
        sub.instance_eval &subnet
        accept sub
      end

      def any &variants
        sub = AnyRule.new
        sub.instance_eval &variants
        accept sub
      end

      def maybe s, p, o, time = 0
        accept OptionalTriple.new( s, p, o, time )
      end

      def same x, y
        EqualityTest.new x, y
      end

      def diff x, y
        UnequalityTest.new x, y
      end

      def asserted s, p, o
        missing s, p, o, -1
        has s, p, o, 0
      end

      def retracted s, p, o
        has s, p, o, -1
        missing s, p, o, 0
      end

      def kept s, p, o
        has s, p, o, -1
        has s, p, o, 0
      end
      alias_method :still_has, :kept

      def kept_missing s, p, o
        missing s, p, o, -1
        missing s, p, o, 0
      end
      alias_method :still_missing, :kept_missing

      def gen s, p, o
        accept GenerationClause.new( Template.new( s, p, o ) )
      end

      def debug *opts
        action = DebugAction.new( @name )
        opts.each do |opt|
          case opt
          when :verbose
            action.verbose!
          when :silent
            action.silent!
          when :values
            action.report_values!
          end
        end
        accept action# if WONGI_DEBUG
      end

      alias_method :generate, :gen

    end

    class ProductionRule < GenericProductionRule

    end

    class NccProductionRule < GenericProductionRule

      def initialize name = nil
        super
        @current_section = :forall
      end

      def import_into model
        NccSet.new @acceptors[:forall].map { |condition|
          if condition.respond_to? :import_into
            condition.import_into(model)
          else
            condition
          end
        }
      end
    end

    class AnyRule

      attr_reader :variants

      def initialize
        @variants = []
      end

      def variant &block
        var = VariantRule.new
        var.instance_eval &block
        variants << var
      end

      def import_into model
        AnySet.new variants.map { |variant|
          if variant.respond_to? :import_into
            variant.import_into(model)
          else
            variant
          end
        }
      end

    end

    class VariantRule < GenericProductionRule

      def initialize name = nil
        super
        @current_section = :forall
      end

      def import_into model
        VariantSet.new @acceptors[:forall].map { |condition|
          if condition.respond_to? :import_into
            condition.import_into(model)
          else
            condition
          end
        }
      end
    end

    class Query < GenericProductionRule

      attr_reader :parameters

      def initialize name
        super
        @parameters = []
      end

      def search_on *terms
        terms.each { |term| @parameters << term }
      end

      def import_into model
        copy = super
        copy.search_on *@parameters
        copy
      end

    end

    #  class Ruleset
    # 
    #    def initialize
    #      @rules = []
    #    end
    # 
    #    def rule name, &definition
    #      r = ProductionRule.new name
    #      r.instance_eval &definition
    #      @rules << r
    #      r
    #    end
    # 
    #    def query name, &definition
    #      r = Query.new name
    #      r.instance_eval &definition
    #      @rules << r
    #      r
    #    end
    # 
    #  end

  end

end

def ruleset name = nil, &definition
  rs = Wongi::Engine::Ruleset.new
  if ! name.nil?
    rs.name name
  end
  rs.instance_eval &definition if block_given?
  rs
end

def rule name, &definition
  r = Wongi::Engine::ProductionRule.new name
  r.instance_eval &definition
  r
end

def dsl &definition
  Wongi::Engine::DSLBuilder.new.build &definition
end
