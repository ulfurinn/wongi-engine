module Wongi
  module Engine
    class ProductionNode < BetaMemory

      attr_accessor :debug

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

    class DebugAction

      attr_accessor :production

      class DefaultDebugger
        class << self
          def report rule, token = nil
            if token
              puts "EXECUTED #{rule} WITH #{token}"
            else
              puts "EXECUTED #{rule}"
            end
          end
        end
      end

      class << self
        attr_writer :production_debugger
        def production_debugger
          @production_debugger || DefaultDebugger
        end
      end

      def initialize rule_name
        @rule_name = rule_name
        @verbose = false
        @values = false
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

      def report *args
        self.class.production_debugger.report *args
      end

      def execute token
        production.debug = @verbose
        if @values
          report @rule_name, token
        else
          report @rule_name
        end
      end
    end

    class StatementGenerator

      attr_accessor :model
      attr_accessor :production

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

        puts "generating wme #{wme}" if production.debug
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
