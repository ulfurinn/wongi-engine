module Wongi::Engine
  class Overlay
    attr_reader :rete, :parent

    private attr_reader :wmes, :tokens
    private attr_reader :indexes
    private attr_reader :queue
    private attr_reader :hidden_parent_wmes
    private attr_reader :hidden_parent_tokens

    private attr_reader :wme_generators
    private attr_reader :hidden_parent_wme_generators

    private attr_reader :wme_manual
    private attr_reader :hidden_parent_wme_manual



    def initialize(rete, parent = nil)
      @rete = rete
      @parent = parent

      @wmes = []
      @indexes = [
        AlphaIndex.new(%i[subject]),
        AlphaIndex.new(%i[predicate]),
        AlphaIndex.new(%i[object]),
        AlphaIndex.new(%i[subject predicate]),
        AlphaIndex.new(%i[subject object]),
        AlphaIndex.new(%i[predicate object]),
      ]
      @hidden_parent_wmes = {}

      @tokens = Hash.new { |h, k| h[k] = [] }
      @hidden_parent_tokens = {}

      @wme_generators = Hash.new { |h, k| h[k] = [] }
      @hidden_parent_wme_generators = {}

      @wme_manual = {}
      @hidden_parent_wme_manual = {}

      @queue = []
    end

    def new_child
      Overlay.new(rete, self)
    end

    def ancestor?(other)
      return false if parent.nil?
      return true if parent == other

      parent.ancestor?(other)
    end

    def dispose!
      return if default?

      tokens.each do |node, tokens|
        tokens.each(&:dispose!)
      end

    end

    def <<(thing)
      case thing
      when Array
        wme = WME.new(*thing).tap { |wme|
          wme.rete = rete
          # wme.overlay = self
        }
        assert(wme)
      when WME
        assert(thing)
      else
        raise Error, "overlays can only accept data"
      end
    end

    def assert(wme, generator: nil)
      operation = [:assert, wme, { generator: }]
      queue.push(operation)

      run_queue if queue.length == 1
    end

    def retract(wme, options = {})
      if wme.is_a?(Array)
        wme = WME.new(*wme)
      end

      operation = [:retract, wme, options]
      queue.push(operation)

      run_queue if queue.length == 1
    end

    def run_queue
      until queue.empty?
        operation, wme, options = queue.shift
        case operation
        when :assert
          wme = find_ignoring_hidden(wme) || wme
          add_wme(wme, **options)
          rete.real_assert(wme)
        when :retract
          wme = find_ignoring_hidden(wme)
          return if wme.nil? # it's perhaps better to return quietly, because complicated cascades may delete a WME while we're going through the queue
          remove_wme(wme, **options)
          rete.real_retract(wme)
        end
      end
    end

    def default?
      self == rete.default_overlay
    end

    # TODO: this is inconsistent.
    # A WME retracted in-flight will be visible in active enumerators
    # but a token will not.
    # But this is how it works.

    # def wmes(template)
    #   DuplicatingEnumerator.new(index(template))
    # end

    # def tokens(beta)
    #   DeleteSafeEnumerator.new(raw_tokens(beta))
    # end

    def find(wme)
      if wme.is_a?(Array)
        wme = WME.new(*wme)
      end
      find_wme(wme)
    end

    def select(*args)
      case args.length
      when 1
        case args.first
        when Template
          select_by_template(args.first)
        else
          raise ArgumentError
        end
      when 3
        select_by_template(Template.new(*args))
      else
        raise ArgumentError
      end
    end

    def manual?(wme)
      wme_manual.key?(wme.object_id) ||
        if parent
          parent.manual?(wme) && !hidden_parent_wme_manual.key?(wme.object_id)
        end
    end

    def generated?(wme)
      generators(wme).any?
    end

    def generated_by?(wme, gen)
      own_generated_by?(wme, gen) ||
        if parent
          parent.generated_by?(wme, gen) && !hidden_parent_wme_generators.key?(gen)
        else
          false
        end
    end

    private def own_generated_by?(wme, gen)
      wme_generators.key?(wme.object_id) && wme_generators[wme.object_id].include?(gen)
    end

    def generators(wme)
      own_generators = wme_generators.key?(wme.object_id) ? wme_generators[wme.object_id] : []
      parent_generators =
        if parent
          parent.generators(wme).reject { |g| hidden_parent_wme_generators.key?(g) }
        else
          []
        end
      own_generators + parent_generators
    end

    private def own_manual?(wme)
      wme_manual.key?(wme.object_id)
    end

    private def own_generated?(wme)
      wme_generators.key?(wme.object_id) && wme_generators[wme.object_id].any?
    end

    private def find_wme(wme)
      find_own_wme(wme) || find_parents_wme(wme)
    end

    private def find_own_wme(wme)
      collections = indexes.map {|index|
        index.collection_for_wme(wme)
      }
      smallest = collections.min_by(&:size)
      smallest.find { _1 == wme }
    end

    private def find_parents_wme(wme)
      if parent
        parent_wme = parent.find(wme)
        parent_wme unless hidden_parent_wmes.key?(parent_wme.object_id)
      else
        nil
      end
    end

    def find_ignoring_hidden(wme)
      find_own_wme(wme) ||
        if parent
          parent.find_ignoring_hidden(wme)
        end
    end

    private def select_by_template(template)
      select_parents_template(template) + select_own_template(template)
    end

    private def select_own_template(template)
      if template.concrete?
        wme = find_own_wme(WME.from_concrete_template(template))
        wme ? [wme] : []
      elsif template.root?
        wmes
      else
        indexes.map { |index|
          index.collections_for_template(template)
        }.compact.first
      end
    end

    private def select_parents_template(template)
      if parent
        parent.select(template).reject { hidden_parent_wmes.key?(_1.object_id) }
      else
        []
      end
    end

    private def add_wme(wme, generator:)
      # p add_wme: { wme:, generator: !!generator }

      # if we previously hid this locally, unhide it
      hidden_parent_wmes.delete(wme.object_id)
      if generator
        hidden_parent_wme_generators.delete(generator)
      else
        hidden_parent_wme_manual.delete(wme.object_id)
      end

      if find_own_wme(wme)
        if generator
          wme_generators[wme.object_id] << generator unless own_generated_by?(wme, generator)
        else
          wme_manual[wme.object_id] = true
        end
      elsif find_parents_wme(wme)
        if generator
          wme_generators[wme.object_id] << generator unless generated_by?(wme, generator)
        else
          wme_manual[wme.object_id] = true unless manual?(wme)
        end
      else
        wmes << wme
        indexes.each { _1.add(wme) }
        if generator
          wme_generators[wme.object_id] << generator
        else
          wme_manual[wme.object_id] = true
        end
      end
    end

    private def remove_wme(wme, generator: nil)
      # p remove_wme: { wme:, generator: !!generator }

      if find_own_wme(wme)
        if generator
          if own_generated_by?(wme, generator)
            wme_generators[wme.object_id].delete(generator)
            wme_generators.delete(wme.object_id) if wme_generators[wme.object_id].empty?
          end
        elsif own_manual?(wme)
          wme_manual.delete(wme.object_id)
        end

        if !own_generated?(wme) && !own_manual?(wme)
          wmes.delete(wme)
          indexes.each { _1.remove(wme) }
        end
      end

      # did we also have an unshadowed parent version?
      return unless find_parents_wme(wme)

      # must be parents' then

      if generator
        # first, delete local
        if own_generated_by?(wme, generator)
          wme_generators[wme.object_id].delete(generator)
          wme_generators.delete(wme.object_id) if wme_generators[wme.object_id].empty?
        end
        # if we're still generated, hide parents'
        if generated_by?(wme, generator)
          hidden_parent_wme_generators[generator] = true
        end
      else
        if own_manual?(wme)
          wme_manual.delete(wme.object_id)
        end
        if manual?(wme)
          hidden_parent_wme_manual[wme.object_id] = true
        end
      end

      if !manual?(wme) && !generated?(wme)
        hidden_parent_wmes[wme.object_id] = true
      end
    end

    def add_token(token)
      # TODO: is this really likely to happen? we don't normally restore deleted tokens but rather create new ones in the activation
      if hidden_parent_tokens.key?(token.object_id)
        hidden_parent_tokens.delete(token.object_id)
        return
      end

      tokens[token.node.object_id].push(token) # unless tokens.include?(token) # TODO: pretty unlikely to somehow trigger a repeated evaluation for the same token?..
    end

    def remove_token(token)
      if own_node_tokens(token.node).find { _1.equal?(token) }.nil?
        if parents_node_tokens(token.node).find { _1.equal?(token) }
          hidden_parent_tokens[token.object_id] = true
        end
        return
      end

      remove_own_token(token)
    end

    def remove_own_token(token)
      tokens[token.node.object_id].delete(token)

      # we know we are the owner, and nobody wants it anymore, so this is the safe place to do it
      token.dispose!
    end

    def node_tokens(beta)
      parents = parents_node_tokens(beta)
      own = own_node_tokens(beta)
      parents + own
    end

    private def own_node_tokens(beta)
      tokens[beta.object_id]
    end

    private def parents_node_tokens(beta)
      if parent
        parent.node_tokens(beta).reject { hidden_parent_tokens.key?(_1.object_id) }
      else
        []
      end
    end
  end
end
