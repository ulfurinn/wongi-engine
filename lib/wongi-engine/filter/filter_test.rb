module Wongi::Engine

  class FilterTest
    def passes?(token)
      raise "#{self.class} must implement #passes?"
    end

    def compile(context)
      context.tap { |c| c.filter_node(self) }
    end

    def ==(other)
      false
    end
  end

end
