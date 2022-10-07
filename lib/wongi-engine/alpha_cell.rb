module Wongi::Engine
  class AlphaCell
    attr_reader :asserted, :retracted
    def initialize
      @asserted = []
      @retracted = []
    end
  end
end
