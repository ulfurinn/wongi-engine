module Wongi::Engine
  class GenericProductionRule

    attr_reader :name
    attr_reader :conditions, :actions

    include DSLExtensions

    class << self

      def section s, *aliases
        unless sections.include?(s)
          sections << s
          define_method s do |&d|
            @current_section = s
            instance_eval &d
          end
          aliases.each { |a| alias_method a, s }
        end
      end
      
      def sections
        @sections ||= []
      end

    end

    section :forall, :for_all
    section :make, :do!

    def initialize name
      @name = name
      @conditions = []
      @actions = []
      @current_section = nil
      @acceptors = {}
      GenericProductionRule.sections.each { |section| @acceptors[section] ||= [] }
    end

    def import_into rete

      copy = self.class.new @name

      copy.conditions = @acceptors[:forall].map do |condition|
        if condition.respond_to? :import_into
          condition.import_into(rete)
        else
          condition
        end
      end

      copy.actions = @acceptors[:make].map do |action|
        if action.respond_to? :import_into
          action.import_into(rete)
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


  end


end
