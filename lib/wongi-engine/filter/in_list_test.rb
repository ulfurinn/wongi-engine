module Wongi::Engine
  class InListTest < FilterTest
    attr_reader :x, :y

    def initialize(x, y)
      super()
      @x = x
      @y = y
    end

    def passes?(token)
      x = if Template.variable? @x
            token[@x]
          else
            @x
          end

      y = if Template.variable? @y
            token[@y]
          else
            @y
          end

      return false if x == :_ || y == :_

      y.include?(x)
    end

    def ==(other)
      super && x == other.x && y == other.y
    end
  end
end
