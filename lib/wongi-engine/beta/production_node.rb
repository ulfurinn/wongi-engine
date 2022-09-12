module Wongi
  module Engine

    class ProductionNode < BetaMemory
      attr_accessor :tracer, :compilation_context

      def initialize(parent, actions)
        super(parent)
        @actions = actions.each { |action| action.production = self }
      end

      def beta_activate(token)
        return unless super

        @actions.each do |action|
          action.execute token if action.respond_to? :execute
        end
      end

      def beta_deactivate(token)
        return unless super

        @actions.each do |action|
          action.deexecute token if action.respond_to? :deexecute
        end
      end
    end

  end
end
