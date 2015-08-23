module Wongi::Engine
  module DSL::Action
    class Base
      include CoreExt
      attr_accessor :production
      attr_accessor :rule
      attr_accessor :name
      attr_accessor :rete
    end
  end
end
