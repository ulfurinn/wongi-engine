module Wongi::Engine

  class FilterTest

    def passes? token
      raise "#{self.class} must implement #passes?"
    end

    def accept_into acceptors
      if acceptors.last && acceptors.last.respond_to?( :filters )
        acceptors.last.filters << self
      else
        acceptors << self
      end
    end

    def compile context
      context.node = context.node.beta_memory.filter_node( self )
      context.node.context = context
      context.earlier << self
      context
    end

    def == other
      false
    end

  end

end
