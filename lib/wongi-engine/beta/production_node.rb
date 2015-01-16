module Wongi
  module Engine
    
    class ProductionNode < BetaMemory

      attr_accessor :tracer

      def initialize parent, actions
        super(parent)
        @actions = actions
        @actions.each { |action| action.production = self }
      end

      def beta_activate token, wme, assignments
        generated = super
        @actions.each do |action|
          # @tokens.each do |t|
          #  action.execute t
          # end
          action.execute generated if action.respond_to? :execute
        end
      end

    end

  end
end
