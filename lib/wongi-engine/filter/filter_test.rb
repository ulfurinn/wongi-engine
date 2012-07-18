module Wongi::Engine

  class FilterTest

    def passes? token
      raise "#{self.class} must implement #passes?"
    end

    def compile context
      context.node = context.node.beta_memory.filter_node( self )
      context.earlier << self
      context
    end

    def == other
      self.class == other.class
    end

  end

end
