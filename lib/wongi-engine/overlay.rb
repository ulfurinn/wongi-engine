module Wongi::Engine
  class Overlay
    class JoinResults
      private attr_reader :by_wme, :by_token
      private attr_reader :hidden
      def initialize()
        @by_wme = Hash.new { |h, k| h[k] = {} }
        @by_token = Hash.new { |h, k| h[k] = {} }
        @hidden = {}
      end

      def for(wme: nil, token: nil)
        if wme
          by_wme.key?(wme.object_id) ? by_wme[wme.object_id].keys : []
        elsif token
          by_token.key?(token.object_id) ? by_token[token.object_id].keys : []
        else
          []
        end
      end

      def has?(jr)
        by_wme.key?(jr.wme.object_id) && by_wme[jr.wme.object_id].key?(jr)
      end

      def hidden?(jr)
        hidden.key?(jr)
      end

      def add(jr)
        if hidden.key?(jr)
          hidden.delete(jr)
        else
          by_wme[jr.wme.object_id][jr] = true
          by_token[jr.token.object_id][jr] = true
        end
      end

      def remove(jr)
        unless has?(jr)
          hide(jr)
          return
        end

        if by_wme.key?(jr.wme.object_id)
          by_wme[jr.wme.object_id].delete(jr)
          if by_wme[jr.wme.object_id].empty?
            by_wme.delete(jr.wme.object_id)
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
        return unless by_wme.key?(wme.object_id)

        by_wme[wme.object_id].keys do |jr|
          remove(jr)
        end
      end
    end

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

    private attr_reader :neg_join_results
    private attr_reader :opt_join_results

    private attr_reader :ncc_tokens
    private attr_reader :ncc_tokens_owner
    private attr_reader :hidden_ncc_tokens

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

      @neg_join_results = JoinResults.new
      @opt_join_results = JoinResults.new

      @ncc_tokens = Hash.new { |h, k| h[k] = [] }
      @ncc_tokens_owner = {}
      @hidden_ncc_tokens = Hash.new { |h, k| h[k] = {} }

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
        assert(WME.new(*thing))
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
        parent_wme unless hidden_wme?(parent_wme)
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
        parent.select(template).reject { hidden_wme?(_1) }
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

        neg_join_results.remove_wme(wme)
        opt_join_results.remove_wme(wme)
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
      # p add_token: {token:}
      # TODO: is this really likely to happen? we don't normally restore deleted tokens but rather create new ones in the activation
      if hidden_token?(token)
        hidden_parent_tokens.delete(token.object_id)
        return
      end

      tokens[token.node.object_id].push(token) # unless tokens.include?(token) # TODO: pretty unlikely to somehow trigger a repeated evaluation for the same token?..
    end

    def remove_token(token)
      # p remove_token: {token:}
      if own_node_tokens(token.node).find { _1.equal?(token) }.nil?
        if parents_node_tokens(token.node).find { _1.equal?(token) }
          hidden_parent_tokens[token.object_id] = true

          # do not hide JRs from the WME side: it will be done in the alpha deactivation and the JRs have to stay visible until then
          parent_neg_join_results_for(token:).each { neg_join_results.hide(_1) }
          parent_opt_join_results_for(token:).each { opt_join_results.hide(_1) }

          parent_ncc_tokens_for(token).each do |ncc|
            hidden_ncc_tokens[token][ncc] = true
          end
        end
        return
      end

      remove_own_token(token)
    end

    def remove_own_token(token)
      # p remove_own_token: {token:}
      tokens[token.node.object_id].delete(token)
      neg_join_results.remove_token(token)
      opt_join_results.remove_token(token)

      # if this is an NCC partner token
      if (owner = ncc_tokens_owner[token])
        if ncc_tokens.key?(owner)
          ncc_tokens[owner].delete(token)
        end
        if hidden_ncc_tokens.key?(owner)
          hidden_ncc_tokens[owner].delete(token)
        end
      end

      # if this is an NCC owner token
      own_ncc_tokens_for(token).each do |ncc|
        ncc_tokens_owner.delete(ncc)
      end
      ncc_tokens.delete(token)
      hidden_ncc_tokens.delete(token)

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

    def add_neg_join_result(njr)
      neg_join_results.add(njr)
    end

    def remove_neg_join_result(njr)
      neg_join_results.remove(njr)
    end

    def neg_join_results_for(wme: nil, token: nil)
      if wme
        neg_join_results.for(wme:) + parent_neg_join_results_for(wme:)
      elsif token
        neg_join_results.for(token:) + parent_neg_join_results_for(token:)
      else
        []
      end
    end

    def add_opt_join_result(ojr)
      opt_join_results.add(ojr)
    end

    def remove_opt_join_result(ojr)
      # p remove_opt_join_result: {ojr:}
      opt_join_results.remove(ojr)
    end

    def opt_join_results_for(wme: nil, token: nil)
      if wme
        opt_join_results.for(wme:) + parent_opt_join_results_for(wme:)
      elsif token
        opt_join_results.for(token:) + parent_opt_join_results_for(token:)
      else
        []
      end
    end

    private def parent_opt_join_results_for(wme: nil, token: nil)
      if parent
        parent.opt_join_results_for(wme:, token:).reject { opt_join_results.hidden?(_1) }
      else
        []
      end
    end

    private def parent_neg_join_results_for(wme: nil, token: nil)
      if parent
        parent.neg_join_results_for(wme:, token:).reject { neg_join_results.hidden?(_1) }
      else
        []
      end
    end

    def add_ncc_token(owner, ncc)
      if hidden_ncc_tokens.key?(owner) && hidden_ncc_tokens[token].include?(ncc)
        hidden_ncc_tokens[owner].delete(ncc)
        if hidden_ncc_tokens[owner].empty?
          hidden_ncc_tokens.delete(owner)
        end
        return
      end

      ncc_tokens[owner] << ncc
      ncc_tokens_owner[ncc] = owner
    end

    def ncc_owner(ncc)
      ncc_tokens_owner[ncc]
    end

    def ncc_tokens_for(token)
      own_ncc_tokens_for(token) + parent_ncc_tokens_for(token)
    end

    private def own_ncc_tokens_for(token)
      ncc_tokens.key?(token) ? ncc_tokens[token] : []
    end

    private def parent_ncc_tokens_for(token)
      if parent
        parent.ncc_tokens_for(token).reject {
          hidden_ncc_tokens.key?(token) && hidden_ncc_tokens[token].key?(_1)
        }
      else
        []
      end
    end

    private def hidden_wme?(wme)
      hidden_parent_wmes.key?(wme.object_id)
    end

    private def hidden_token?(token)
      hidden_parent_tokens.key?(token.object_id)
    end
  end
end
