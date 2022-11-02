module Wongi::Engine
  class RootNode < BetaNode
    def seed(assignments = {})
      @seed = assignments
      t = Token.new(self, nil, nil, assignments)
      rete.default_overlay.add_token(t)
    end

    def subst(valuations)
      beta_deactivate(tokens.first)
      token = Token.new(self, nil, nil, @seed)
      valuations.each { |variable, value| token.subst variable, value }
      beta_activate(token)
    end

    def beta_activate(token)
      # existing = tokens.find { |et| et.duplicate? token }
      # return if existing # TODO: really?

      overlay.add_token(token)

      children.each do |child|
        child.beta_activate(Token.new(child, token, nil))
      end

      nil
    end

    def beta_deactivate(token)
      return nil unless tokens.find token

      overlay.remove_token(token)

      children.each do |child|
        child.tokens.select { _1.child_of?(token) }.each { child.beta_deactivate(_1) }
      end

      nil
    end

    def refresh_child(child)
      tokens.each do |token|
        child.beta_activate(Token.new(child, token, nil))
      end
    end
  end
end
