module Wongi::Engine
  class AssignmentNode < BetaNode
    attr_reader :variable, :body

    def initialize(parent, variable, body)
      super(parent)
      @variable = variable
      @body = body
    end

    def beta_activate(token, _wme = nil, _assignments = {})

      overlay.add_token(token)
      children.each do |child|
        value = body.respond_to?(:call) ? body.call(token) : body
        child.beta_activate Token.new(child, token, nil, { variable => value })
      end
    end

    def beta_deactivate(token)
      overlay.remove_token(token)
      children.each do |child|
        child.tokens.each do |t|
          if t.child_of?(token)
            child.beta_deactivate t
            # token.destroy
          end
        end
      end
    end

    def refresh_child(child)
      tokens.each do |token|
        child.beta_activate Token.new(child, token, nil, { variable => body.respond_to?(:call) ? body.call(token) : body })
      end
    end
  end
end
