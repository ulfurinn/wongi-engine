module Wongi::Engine

  class Assignment

    def initialize variable, &body
      @variable, @body = variable, body
    end

    def compile context
      context.node = context.node.beta_memory.assignment_node( @variable, @body )
      context.earlier << self
      context
    end

  end

  class AssignmentNode < BetaNode

    def initialize parent, variable, body
      super parent
      @variable, @body = variable, body
    end

    def beta_activate token, wme = nil, assignments = { }
      propagate_activation token, nil, { @variable => @body }
    end

    def refresh_child child
      tmp = children
      self.children = [ child ]
      parent.tokens.each do |token|
        beta_activate token
      end
      self.children = tmp
    end

  end

end
