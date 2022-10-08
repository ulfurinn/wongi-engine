module Wongi::Engine
  TokenAssignment = Struct.new(:wme, :field) do
    def call(_token = nil)
      wme.send field
    end

    def inspect
      "#{field} of #{wme}"
    end

    def to_s
      inspect
    end
  end
end
