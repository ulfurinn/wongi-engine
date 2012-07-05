module Wongi
  module Engine
    class ProductionNode < BetaMemory

      attr_accessor :tracer

      def initialize parent, actions
        super(parent)
        @actions = actions
        @actions.each { |action| action.production = self }
      end

      def left_activate token, wme, assignments
        super
        @actions.each do |action|
          # @tokens.each do |t|
          #  action.execute t
          # end
          action.execute last_token if action.respond_to? :execute
        end
      end

      # => TODO: investigate
      def deexecute token

      end
    end

    class StatementGenerator < Action

      def initialize template
        @template = template
      end

      def execute token

        subject = if Template.variable?( @template.subject )
          v = token[ @template.subject ]
          raise "Unbound variable #{@template.subject} in token #{token}" if v.nil?
          v
        else
          @template.subject
        end

        predicate = if Template.variable?( @template.predicate )
          v = token[ @template.predicate ]
          raise "Unbound variable #{@template.predicate} in token #{token}" if v.nil?
          v
        else
          @template.predicate
        end

        object = if Template.variable?( @template.object )
          v = token[ @template.object ]
          raise "Unbound variable #{@template.object} in token #{token}" if v.nil?
          v
        else
          @template.object
        end

        wme = WME.new subject, predicate, object

        production.tracer.trace( action: self, wme: wme ) if production.tracer
        if existing = model.exists?( wme )
          generated = existing.generating_tokens.size
          if generated > 0 && ! token.generated_wmes.include?( existing )
            token.generated_wmes << existing
            existing.generating_tokens << token
          end
        else
          added = model << wme
          token.generated_wmes << added
          added.generating_tokens << token
        end
    
      end

    end
  end
end
