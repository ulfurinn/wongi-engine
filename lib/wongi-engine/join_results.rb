module Wongi::Engine
  class JoinResults
    attr_reader :by_wme, :by_token, :hidden
    private :by_wme, :by_token
    private :hidden
    def initialize
      @by_wme = Hash.new { |h, k| h[k] = {} }
      @by_token = Hash.new { |h, k| h[k] = {} }
      @hidden = {}
    end

    def for(wme: nil, token: nil)
      if wme
        by_wme.key?(wme) ? by_wme[wme].keys : []
      elsif token
        by_token.key?(token.object_id) ? by_token[token.object_id].keys : []
      else
        []
      end
    end

    def has?(jr)
      by_wme.key?(jr.wme) && by_wme[jr.wme].key?(jr)
    end

    def hidden?(jr)
      hidden.key?(jr)
    end

    def add(jr)
      if hidden.key?(jr)
        hidden.delete(jr)
      else
        by_wme[jr.wme][jr] = true
        by_token[jr.token.object_id][jr] = true
      end
    end

    def remove(jr)
      unless has?(jr)
        hide(jr)
        return
      end

      if by_wme.key?(jr.wme)
        by_wme[jr.wme].delete(jr)
        if by_wme[jr.wme].empty?
          by_wme.delete(jr.wme)
        end
      end

      if by_token.key?(jr.token.object_id)
        by_token[jr.token.object_id].delete(jr)
        if by_token[jr.token.object_id].empty?
          by_token.delete(jr.token.object_id)
        end
      end
    end

    def hide(jr)
      hidden[jr] = true
    end

    def remove_token(token)
      return unless by_token.key?(token.object_id)

      by_token[token.object_id].keys.each do |jr|
        remove(jr)
      end
    end

    def remove_wme(wme)
      return unless by_wme.key?(wme)

      by_wme[wme].keys do |jr|
        remove(jr)
      end
    end
  end
end
