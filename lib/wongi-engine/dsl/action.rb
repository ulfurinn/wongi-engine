module Wongi::Engine
  class Action

    include CoreExt

    attr_accessor :production
    attr_accessor :rete
    attr_accessor :rule

    def self.category category = nil
      if category
        @category = category
      end
      @category
    end

    def category
      self.class.category
    end

  end
end
