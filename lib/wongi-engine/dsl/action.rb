module Wongi::Engine
  class Action

    include CoreExt

    attr_accessor :production
    attr_accessor :rule
    attr_accessor :name
    attr_accessor :rete

  end
end
