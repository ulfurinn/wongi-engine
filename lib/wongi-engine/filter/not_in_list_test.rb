module Wongi::Engine
  class NotInListTest < FilterTest
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

      !y.include?(x)
    end

    def ==(other)
      self.class == other.class && x == other.x && y == other.y
    end

    def to_s
      "#{x} not in #{y}"
    end
  end
end
