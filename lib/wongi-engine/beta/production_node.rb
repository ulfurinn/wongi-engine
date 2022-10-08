module Wongi
  module Engine
    class ProductionNode < BetaNode
      attr_accessor :tracer, :compilation_context

      def initialize(parent, actions)
        super(parent)
        @actions = actions.each { |action| action.production = self }
      end

      def beta_activate(token)
        overlay.add_token(token)

        @actions.each do |action|
          action.execute token if action.respond_to? :execute
        end
      end

      def beta_deactivate(token)
        @actions.each do |action|
          action.deexecute token if action.respond_to? :deexecute
        end
        # do not dispose before the actions have run
        overlay.remove_token(token)
      end
    end
  end
end
