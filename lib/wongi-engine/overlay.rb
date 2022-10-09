module Wongi::Engine
  class Overlay
    attr_reader :rete, :parent

    private attr_reader :wmes, :tokens
    private attr_reader :indexes
    private attr_reader :queue
    private attr_reader :hidden_parent_wmes
    private attr_reader :hidden_parent_tokens

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
        assert(WME.new(*thing).tap { |wme|
          wme.rete = rete
          # wme.overlay = self
        })
      when WME
        assert(thing)
      else
        raise Error, "overlays can only accept data"
      end
    end

    def assert(wme)
      operation = [:assert, wme]
      queue.push(operation)

      run_queue if queue.length == 1
    end

    def retract(wme, options = {})
      real = if wme.is_a? Array
        wme = WME.new(*wme)
        rete.find(wme.subject, wme.predicate, wme.object)
      else
        wme
      end
      return unless real

      wme = real

      operation = [:retract, wme, options]
      queue.push(operation)

      run_queue if queue.length == 1
    end

    def run_queue
      until queue.empty?
        operation, wme, options = queue.shift
        case operation
        when :assert
          add_wme(wme)
          rete.real_assert(wme)
        when :retract
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

    def find(wme, with_manual: nil)
      if wme.is_a?(Array)
        wme = WME.new(*wme)
      end
      find_wme(wme, with_manual:)
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

    private def find_wme(wme, with_manual: nil)
      own_wme = find_own_wme(wme)
      if own_wme && (with_manual.nil? || own_wme.manual? == with_manual)
        return own_wme
      end
      find_parents_wme(wme, with_manual:)
    end

    private def find_own_wme(wme)
      collections = indexes.map {|index|
        index.collection_for_wme(wme)
      }
      smallest = collections.min_by(&:size)
      smallest.find { _1 == wme }
    end

    private def find_parents_wme(wme, with_manual: nil)
      if parent
        parent_wme = parent.find(wme, with_manual:)
        parent_wme unless hidden_parent_wmes.key?(parent_wme.object_id)
      else
        nil
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

    private def add_wme(wme)
      # p add_wme: {wme:, generated: wme.generated?}
      if hidden_parent_wmes.key?(wme.object_id)
        hidden_parent_wmes.delete(wme.object_id)
        return
      end

      if (own_wme = find_own_wme(wme))
        own_wme.manual! if wme.manual?
        return
      end

      if (existing = find_parents_wme(wme))
        # generated in parent but manual here - must track separately
        return unless wme.manual? && !existing.manual?
      end

      wmes << wme
      indexes.each { _1.add(wme) }
    end

    private def remove_wme(wme, automatic: false)
      # p remove_wme: {wme:, automatic:}
      found_wme = find_own_wme(wme)
      if found_wme
        if !automatic && found_wme.generated?
          if found_wme.manual?
            # a gen action is still holding on to this, so just clear the manual flag
            found_wme.manual = false
          else
            raise StandardError, "cannot manually retract automatically generated facts"
          end
        end

        delete =
          (automatic && !found_wme.manual?) || # manual is an override
          (!automatic && !found_wme.generated?)

        if delete
          wmes.delete(found_wme)
          indexes.each { _1.remove(found_wme) }
        end

        return
      end

      if automatic
        parents_wme = find_parents_wme(wme, with_manual: false)
        if parents_wme
          hidden_parent_wmes[parents_wme.object_id] = true
        else
          # TODO: is it possible to have a manual one in the parents but no local ones?
          raise StandardError, "retracting non-existing wme #{wme}"
        end
      else
        # we can have a mix of manual and generated WMEs in the overlay lineage;
        # only retract local if we can have a manual one – and retract that one specifically by its object_id,
        # leaving any generated ones visible
        parents_wme = find_parents_wme(wme, with_manual: true)
        if parents_wme
          hidden_parent_wmes[parents_wme.object_id] = true
        elsif find_parents_wme(wme, with_manual: false)
          raise StandardError, "cannot manually retract automatically generated facts"
        else
          raise StandardError, "retracting non-existing wme"
        end
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
