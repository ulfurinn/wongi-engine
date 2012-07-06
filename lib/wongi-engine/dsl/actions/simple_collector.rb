module Wongi::Engine

  class SimpleCollector < Action

    def initialize variable, name = nil
      @variable = variable
      @name = name if name
    #(class << self; self; end).instance_eval do
        #        define_method method do
        #          collect variable
        #        end
    #    alias_method method, :default_collect
    #  end
    end

    def default_collect
      collect @variable
    end

    def name= n
      @name = n unless @name
    end

    def rete= rete
      rete.add_collector self, name
    end

    def collect var
      production.tokens.map { |token| token[var] }
    end

  end

  class GenericCollectClause

    def initialize name, variable

    end

    def import_into rete
      collector = SimpleCollector.new @variable

    end

  end

end
