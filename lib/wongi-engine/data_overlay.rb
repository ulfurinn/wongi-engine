module Wongi::Engine
  class DataOverlay
    attr_reader :rete, :parent
    attr_reader :wmes
    attr_reader :operations

    def initialize(rete, parent = nil)
      @rete = rete
      @parent = parent

      @index = Hash.new { |h, k| h[k] = AlphaCell.new }
      @index[]

      @wmes = index(Template.new(:_, :_, :_))

      @raw_tokens = Hash.new { |h, k| h[k] = [] }
      @operations = []
      rete.add_overlay(self)
    end

    def index(template)
      @index[template.hash]
    end

    def new_child
      DataOverlay.new(rete, self)
    end

    def with_child
      return unless block_given?

      new_child.tap do |overlay|
        yield overlay
      ensure
        overlay.dispose
      end
    end

    def ancestor?(other)
      return false if parent.nil?
      return true if parent == other

      parent.ancestor?(other)
    end

    def dispose
      return if default?

      rete.remove_overlay(self)

      operations.reverse.each do |(operation, wme, options)|
        case operation
        when :assert
          rete.real_retract(wme, {})
        when :retract
          rete.real_assert(wme)
        end
      end

    end

    def <<(thing)
      case thing
      when Array
        assert(WME.new(*thing).tap { |wme|
          wme.rete = rete
          wme.overlay = self
        })
      when WME
        assert(thing)
      else
        raise Error, "overlays can only accept data"
      end
    end

    def assert(wme)
      p assert: {wme:}
      wme.overlay = self
      operation = [:assert, wme]
      operations << operation unless default? || wme.generated?

      @next_cascade ||= []
      @next_cascade << operation

      return if @current_cascade

      @current_cascade = @next_cascade
      @next_cascade = nil
      process_cascade
    end

    def retract(wme, options = {})
      p retract: {wme:}
      real = if wme.is_a? Array
        wme = WME.new(*wme)
        rete.find(wme.subject, wme.predicate, wme.object)
      else
        wme
      end
      p real:;
      return unless real
      wme = real

      operation = [:retract, wme, options]
      operations << operation unless default? || options[:automatic]

      @next_cascade ||= []
      @next_cascade << operation
      return if @current_cascade

      @current_cascade = @next_cascade
      @next_cascade = nil
      process_cascade
    end

    def process_cascade
      while @current_cascade
        p :cascade
        @current_cascade.each do |(operation, wme, options)|
          case operation
          when :assert
            rete.real_assert(wme)
          when :retract
            rete.real_retract(wme, options)
          end
        end
        @current_cascade = @next_cascade
        @next_cascade = nil
      end
      p :cascades_done
    end

    def highest(other)
      return self if self == other
      return self if other.nil?
      return self if ancestor?(other)
      return other if other.ancestor?(self)

      nil # unrelated lineages
    end

    def default?
      self == rete.default_overlay
    end

    # TODO: this is inconsistent.
    # A WME retracted in-flight will be visible in active enumerators
    # but a token will not.
    # But this is how it works.

    def wmes(template)
      DuplicatingEnumerator.new(index(template))
    end

    def tokens(beta)
      DeleteSafeEnumerator.new(raw_tokens(beta))
    end

    def add_wme(wme)
      return if find(wme)
      wmes = index(alpha)
      wmes << wme unless wmes.include?(wme)
    end

    def remove_wme(wme)
      wmes.delete(wme)
    end

    def add_token(token)
      tokens = raw_tokens(token.owner)
      tokens << token unless tokens.include?(token)
    end

    def remove_token(token)
      raw_tokens(token.owner).delete(token)
    end

    def raw_tokens(beta)
      @raw_tokens[beta.object_id]
    end
  end
end
