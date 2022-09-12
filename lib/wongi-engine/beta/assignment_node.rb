module Wongi::Engine

  class AssignmentNode < BetaNode
    def initialize(parent, variable, body)
      super(parent)
      @variable = variable
      @body = body
    end

    def beta_activate(token, wme = nil, _assignments = {})
      children.each do |child|
        child.beta_activate Token.new(child, token, nil, { @variable => @body.respond_to?(:call) ? @body.call(token) : @body })
      end
    end

    def beta_deactivate(token)
      children.each do |child|
        child.tokens.each do |t|
          if t.parent == token
            child.beta_deactivate t
            #token.destroy
          end
        end
      end
    end

    def refresh_child(child)
      tmp = children
      self.children = [child]
      parent.tokens.each do |token|
        children.each do |child|
          child.beta_activate Token.new(child, token, nil, { @variable => @body.respond_to?(:call) ? @body.call(token) : @body })
        end
      end
      self.children = tmp
    end
  end

end
