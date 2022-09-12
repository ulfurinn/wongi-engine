module Wongi::Engine
  class FilterTest
    def passes?(_token)
      raise "#{self.class} must implement #passes?"
    end

    def compile(context)
      context.tap { |c| c.filter_node(self) }
    end

    def ==(_other)
      false
    end
  end
end
