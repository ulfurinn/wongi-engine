module Wongi::Engine
  class GeneratorTracker
    def initialize
      @by_wme = Hash.new { |h, k| h[k] = Set.new }
      @by_token = Hash.new { |h, k| h[k] = Set.new }
    end

    def add(wme, token)
      @by_wme[wme].add(token)
      @by_token[token.object_id].add(wme)
    end

    def for_wme(wme)
      @by_wme.has_key?(wme) ? @by_wme[wme] : Set.new
    end

    def for_token(token)
      @by_token.has_key?(token.object_id) ? @by_token[token.object_id] : Set.new
    end

    def remove_token(token)
      wmes = for_token(token)
      @by_token.delete(token.object_id)
      wmes.each do |wme|
        next unless @by_wme.key?(wme)

        @by_wme[wme].delete(token)
        @by_wme.delete(wme) if @by_wme[wme].empty?
      end
    end
  end
end
