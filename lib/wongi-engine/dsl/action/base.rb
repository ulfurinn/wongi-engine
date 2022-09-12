module Wongi::Engine
  module DSL::Action
    class Base
      include CoreExt
      attr_accessor :production, :rule, :name, :rete
    end
  end
end
