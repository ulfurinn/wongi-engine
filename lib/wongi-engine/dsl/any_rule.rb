module Wongi::Engine
  class AnyRule

    attr_reader :variants

    def initialize &block
      @variants = []
      if block
        instance_eval &block
      end
    end

    def variant &block
      var = VariantRule.new
      var.instance_eval &block
      variants << var
    end

    def import_into rete
      AnySet.new variants.map { |variant|
        if variant.respond_to? :import_into
          variant.import_into(rete)
        else
          variant
        end
      }
    end

  end

  class VariantRule < GenericProductionRule

    def initialize name = nil
      super
      @current_section = :forall
    end

    def import_into rete
      VariantSet.new @acceptors[:forall].map { |condition|
        if condition.respond_to? :import_into
          condition.import_into(rete)
        else
          condition
        end
      }
    end
  end
end
