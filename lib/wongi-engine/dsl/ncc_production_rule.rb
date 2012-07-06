module Wongi::Engine
  class NccProductionRule < GenericProductionRule

    def initialize name = nil, &block
      super
      if block
        instance_eval &block
      end
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
end
