module Wongi::Engine

  class SimpleCollector < Action

    def initialize variable, method
      @variable = variable
      (class << self; self; end).instance_eval do
          #        define_method method do
          #          collect variable
          #        end
          alias_method method, :default_collect
        end
      end

      def default_collect
        collect @variable
      end

      def model= model
        super
        model.add_collector self, category
      end

      def collect var
        production.tokens.map { |token| token[var] }
      end

    end

  end
