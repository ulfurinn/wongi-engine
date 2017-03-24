module Wongi::Engine
  module DSL
    class Rule

    attr_reader :name

    class << self

      def section s, *aliases
        unless sections.include?(s)
          sections << s
          define_method s do |&d|
            @current_section = s
            section = DSL.sections[s].new
            section.rule = self
            section.instance_eval &d
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
      @current_section = nil
        Rule.sections.each { |section| acceptors[section] ||= [] }
    end

    def acceptors
      @acceptors ||= {}
    end

    def conditions
      acceptors[:forall] ||= []
    end

    def conditions= c
      acceptors[:forall] = c
    end

    def actions
      acceptors[:make] ||= []
    end

    def actions= a
      acceptors[:make] = a
    end

    def import_into rete
      self.class.new( @name ).tap do |copy|
        copy.conditions = conditions

        copy.actions = actions.map do |action|
          if action.respond_to? :import_into
            action.import_into(rete)
          else
            action
          end
        end
      end
    end

    def install( rete )
      rete.install_rule( self )
    end

    def accept stuff
      acceptors[@current_section] << stuff
    end


  end
  end
end
