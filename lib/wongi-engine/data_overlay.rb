module Wongi::Engine
  class DataOverlay

    attr_reader :rete
    attr_reader :parent

    def initialize(rete, parent = nil)
      @rete = rete
      @parent = parent
      rete.add_overlay(self)
    end

    def new_child
      DataOverlay.new(rete, self)
    end

    def with_child
      return unless block_given?
      new_child.tap do |overlay|
        begin
          result = yield overlay
        ensure
          overlay.dispose
        end
        result
      end
    end

    def ancestor?(other)
      return false if parent.nil?
      return true if parent == other
      parent.ancestor?(other)
    end

    def dispose
      return if self == rete.default_overlay
      rete.remove_overlay(self)
    end

    def <<(thing)
      case thing
      when Array
        assert WME.new(*thing)
      when WME
        assert(thing)
      else
        raise Error, "overlays can only accept data"
      end
    end

    def assert wme
      @next_cascade ||= []
      @next_cascade << [:assert, wme]
      if @current_cascade.nil?
        @current_cascade = @next_cascade
        @next_cascade = nil
        process_cascade
      end
    end

    def retract wme, options = { }
      if wme.is_a? Array
        wme = WME.new(*wme)
      end
      @next_cascade ||= []
      @next_cascade << [:retract, wme, options]
      if @current_cascade.nil?
        @current_cascade = @next_cascade
        @next_cascade = nil
        process_cascade
      end
    end

    def process_cascade
      while @current_cascade
        @current_cascade.each do |(operation, wme, options)|
          case operation
          when :assert
            wme.overlay = self
            rete.real_assert(wme)
          when :retract
            rete.real_retract(wme, options)
            wme.overlay = nil
          end
        end
        @current_cascade = @next_cascade
        @next_cascade = nil
      end
    end

    def highest(other)
      return self if self == other
      return self if other.nil?
      return self if ancestor?(other)
      return other if other.ancestor?(self)
      nil # unrelated lineages
    end

    # TODO: this is inconsistent.
    # A WME retracted in-flight will be visible in active enumerators
    # but a token will not.
    # But this is how it works.

    def wmes(alpha)
      DuplicatingEnumerator.new(raw_wmes(alpha))
    end

    def tokens(beta)
      DeleteSafeEnumerator.new(raw_tokens(beta))
    end

    def add_wme(wme, alpha)
      wmes = raw_wmes(alpha)
      wmes << wme unless wmes.include?(wme)
    end

    def remove_wme(wme, alpha)
      raw_wmes(alpha).delete(wme)
    end

    def add_token(token, beta)
      tokens = raw_tokens(beta)
      tokens << token unless tokens.include?(token)
    end

    def remove_token(token, beta)
      raw_tokens(beta).delete(token)
    end

    def raw_wmes(alpha)
      @raw_wmes ||= Hash.new { |h, k| h[k] = [] }
      @raw_wmes[alpha.object_id]
    end

    def raw_tokens(beta)
      @raw_tokens ||= Hash.new { |h, k| h[k] = [] }
      @raw_tokens[beta.object_id]
    end
  end
end
