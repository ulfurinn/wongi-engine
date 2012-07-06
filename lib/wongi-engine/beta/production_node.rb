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

  end
end
