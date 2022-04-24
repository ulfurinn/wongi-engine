module Wongi::Engine

  class BetaMemory < BetaNode
    include TokenContainer

    def seed(assignments = {})
      @seed = assignments
      t = Token.new(self, nil, nil, assignments)
      rete.default_overlay.add_token(t, self)
    end

    def subst(valuations)
      beta_deactivate(tokens.first)
      token = Token.new(self, nil, nil, @seed)
      valuations.each { |variable, value| token.subst variable, value }
      beta_activate(token)
    end

    def beta_activate(token)
      existing = tokens.find { |et| et.duplicate? token }
      return if existing # TODO really?
      token.overlay.add_token(token, self)
      children.each do |child|
        child.beta_activate token
      end
      token
    end

    def beta_deactivate(token)
      return nil unless tokens.find token
      token.overlay.remove_token(token, self)
      token.deleted!
      if token.parent
        token.parent.children.delete token # should this go into Token#destroy?
      end
      children.each do |child|
        child.beta_deactivate token
      end
      token
    end

    def refresh_child(child)
      tokens.each do |token|
        child.beta_activate token
      end
    end

  end

  # SingletonBetaMemory is a memory node that only holds one token at a time.
  # It should only be used after aggregate nodes.
  class SingletonBetaMemory < BetaMemory
    def beta_activate(token)
      if (t = tokens.first)
        beta_deactivate(t)
      end
      super
    end
  end
end
