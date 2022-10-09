module Wongi
  module Engine
    class ProductionNode < BetaNode
      attr_accessor :tracer, :compilation_context

      def initialize(parent, actions)
        super(parent)
        @actions = actions.each { |action| action.production = self }
      end

      def beta_activate(token)
        # p beta_activate: {class: self.class, object_id:, token:}
        return if tokens.find { |t| t.duplicate? token }

        overlay.add_token(token)

        @actions.each do |action|
          action.execute token if action.respond_to? :execute
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}

        # we should remove before the actions because otherwise the longer rule chains (like the infinite neg-gen cycle) don't work as expected
        overlay.remove_token(token)

        @actions.each do |action|
          action.deexecute token if action.respond_to? :deexecute
        end
      end
    end
  end
end
