module Wongi::Engine

  class BetaMemory < BetaNode

    def initialize parent
      super
      @tokens = []
    end

    # @override
    def beta_memory
      self
    end

    def seed assignments = {}
      @seed = assignments
      t = Token.new( self, nil, nil, assignments )
      @tokens << t
    end

    def subst valuations
      @tokens.first.destroy

      token = Token.new( self, nil, nil, @seed )
      @tokens << token

      valuations.each { |variable, value| token.subst variable, value }
      self.children.each do |child|
        child.beta_activate token
      end
    end

    def beta_activate token
      existing = @tokens.reject(&:deleted?).find { |et| et.duplicate? token }
      return if existing # TODO really?
      @tokens << token
      children.each do |child|
        child.beta_activate token
      end
      token
    end

    def beta_deactivate token
      return nil unless tokens.find token
      @tokens.delete token
      token.deleted!
      if token.parent
        token.parent.children.delete token # should this go into Token#destroy?
      end
      children.each do |child|
        child.beta_deactivate token
      end
      token
    end

    def refresh_child child
      tokens.each do |token|
        child.beta_activate token
      end
    end

    # def delete_token token
    #   @tokens.delete token
    # end

    # => TODO: investigate if we really need this
    #def beta_memory
    #  self
    #end

  end

end
