module Wongi::Engine
  class AlphaIndex
    attr_reader :pattern, :index
    private :pattern
    private :index

    def initialize(pattern)
      @pattern = pattern
      @index = Hash.new { |h, k| h[k] = Set.new }
    end

    def add(wme)
      collection_for_wme(wme).add(wme)
    end

    def remove(wme)
      collection = collection_for_wme(wme)
      collection.delete(wme)

      # release some memory
      index.delete(hashed_key(wme)) if collection.empty?
    end

    def collection_for_wme(wme)
      index[hashed_key(wme)]
    end

    private def key(wme)
      pattern.map { wme.public_send(_1) }
    end

    private def hashed_key(wme)
      key(wme).map(&:hash)
    end
  end
end
