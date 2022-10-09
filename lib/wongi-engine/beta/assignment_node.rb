module Wongi::Engine
  class AssignmentNode < BetaNode
    def initialize(parent, variable, body)
      super(parent)
      @variable = variable
      @body = body
    end

    def beta_activate(token, _wme = nil, _assignments = {})
      return if tokens.find { |t| t.duplicate? token }

      overlay.add_token(token)
      children.each do |child|
        value = @body.respond_to?(:call) ? @body.call(token) : @body
        p value:;
        child.beta_activate Token.new(child, token, nil, { @variable => value })
      end
    end

    def beta_deactivate(token)
      overlay.remove_token(token)
      children.each do |child|
        child.tokens.each do |t|
          if t.parent == token
            child.beta_deactivate t
            # token.destroy
          end
        end
      end
    end

    def refresh_child(child)
      tokens.each do |token|
        child.beta_activate Token.new(child, token, nil, { @variable => @body.respond_to?(:call) ? @body.call(token) : @body })
      end
    end
  end
end
