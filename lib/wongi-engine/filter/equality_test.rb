module Wongi::Engine

  class EqualityTest < FilterTest

    attr_reader :x, :y

    def initialize(x, y)
      @x, @y = x, y
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

      x == y
    end

    def ==(other)
      super && x == other.x && y == other.y
    end

  end

end
