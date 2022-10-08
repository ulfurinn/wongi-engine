module Wongi::Engine
  module DSL::Action
    class SimpleCollector < BaseAction
      def self.collector
        Class.new self
      end

      def initialize(variable, name = nil)
        super()
        @variable = variable
        @name = name if name
        # (class << self; self; end).instance_eval do
        #        define_method method do
        #          collect variable
        #        end
        #    alias_method method, :default_collect
        #  end
      end

      def default_collect
        collect @variable
      end

      def name=(n)
        @name ||= n
      end

      def rete=(rete)
        rete.add_collector self, name
      end

      def collect(var)
        production.tokens.map { |token| token[var] }
      end
    end
  end
end
