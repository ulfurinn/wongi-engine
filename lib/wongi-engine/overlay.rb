module Wongi::Engine
  class Overlay

    attr_reader :rete, :parent, :wmes, :tokens, :indexes, :queue, :hidden_parent_wmes, :hidden_parent_tokens, :generator_tracker, :wme_manual, :hidden_parent_wme_manual, :neg_join_results, :opt_join_results, :ncc_tokens, :ncc_tokens_owner, :hidden_ncc_tokens
    private :wmes, :tokens
    private :indexes
    private :queue
    private :hidden_parent_wmes
    private :hidden_parent_tokens
    private :generator_tracker
    private :wme_manual
    private :hidden_parent_wme_manual
    private :neg_join_results
    private :opt_join_results
    private :ncc_tokens
    private :ncc_tokens_owner
    private :hidden_ncc_tokens

    def initialize(rete, parent = nil)
      @rete = rete
      @parent = parent

      @wmes = Set.new
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
      @hidden_parent_tokens = Set.new

      @generator_tracker = GeneratorTracker.new

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
      operation = [:assert, wme, { generator: generator }]
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
          existing_wme = find_ignoring_hidden(wme)
          wme = existing_wme || wme
          visible = !find(wme).nil?
          add_wme(wme, **options)
          rete.real_assert(wme) unless visible

        when :retract
          wme = find_ignoring_hidden(wme)
          if wme # it's perhaps better to return quietly, because complicated cascades may delete a WME while we're going through the queue
            visible = !find(wme).nil?
            remove_wme(wme, **options)
            rete.real_retract(wme) if visible
          end

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
      wme_manual.key?(wme) ||
        if parent
          parent.manual?(wme) && !hidden_parent_wme_manual.key?(wme)
        end
    end

    def generated?(wme)
      generators(wme).any?
    end

    def generators(wme)
      Enumerator.new do |y|
        generator_tracker.for_wme(wme).each {  y << _1 }
        if parent
          parent.generators(wme).reject { hidden_token?(_1) }.each { y << _1 }
        end
      end
    end

    def generated_wmes(token)
      Enumerator.new do |y|
        generator_tracker.for_token(token).each { y << _1 }
        if parent && !hidden_token?(token)
          parent.generated_wmes(token).reject { hidden_wme?(_1) }.each { y << _1 }
        end
      end
    end

    private def own_manual?(wme)
      wme_manual.key?(wme)
    end

    private def own_generated?(wme)
      generator_tracker.for_wme(wme).any?
    end

    private def find_wme(wme)
      find_own_wme(wme) || find_parents_wme(wme)
    end

    private def find_own_wme(wme)
      has_own_wme?(wme) ? wme : nil
    end

    private def has_own_wme?(wme) = wmes.include?(wme)

    private def find_parents_wme(wme)
      return unless parent

      parent_wme = parent.find(wme)
      parent_wme unless hidden_wme?(parent_wme)
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
        parent.select(template).reject { hidden_wme?(_1) }.to_set
      else
        Set.new
      end
    end

    private def add_wme(wme, generator:)
      # p add_wme: { wme:, generator: !!generator }

      # if we previously hid this locally, unhide it
      hidden_parent_wmes.delete(wme)

      unless has_own_wme?(wme)
        wmes.add(wme)
        indexes.each { _1.add(wme) }
      end

      if generator
        generator_tracker.add(wme, generator)
      else
        hidden_parent_wme_manual.delete(wme)
        wme_manual[wme] = true
      end
    end

    private def remove_wme(wme, generator: nil)
      # p remove_wme: { wme:, generator: !!generator }

      if find_own_wme(wme)
        wme_manual.delete(wme) if generator.nil?

        # no remaining reasons to keep this WME around
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

      if generator.nil?
        wme_manual.delete(wme)
        # if still manual, it must be from the parent
        hidden_parent_wme_manual[wme] = true if manual?(wme)
      end

      if !manual?(wme) && !generated?(wme)
        hidden_parent_wmes[wme] = true
      end
    end

    def add_token(token)
      # p add_token: {token:}
      # TODO: is this really likely to happen? we don't normally restore deleted tokens but rather create new ones in the activation
      if hidden_token?(token)
        puts "odd case"
        unhide_token(token)
        return
      end

      tokens[token.node.object_id].push(token) # unless tokens.include?(token) # TODO: pretty unlikely to somehow trigger a repeated evaluation for the same token?..
    end

    def remove_token(token)
      # p remove_token: {token:}

      # capture the entire enumerated state
      wmes = generated_wmes(token).to_a

      if own_node_tokens(token.node).find { _1.equal?(token) }.nil?
        if parents_node_tokens(token.node).find { _1.equal?(token) }
          hide_token(token)

          # do not hide JRs from the WME side: it will be done in the alpha deactivation and the JRs have to stay visible until then
          parent_neg_join_results_for(token: token).each { neg_join_results.hide(_1) }
          parent_opt_join_results_for(token: token).each { opt_join_results.hide(_1) }

          parent_ncc_tokens_for(token).each do |ncc|
            hidden_ncc_tokens[token][ncc] = true
          end
        end
      else
        remove_own_token(token)
      end

      wmes.each { retract(_1, generator: token) }

    end

    def remove_own_token(token)
      # p remove_own_token: {token:}
      tokens[token.node.object_id].delete(token)
      neg_join_results.remove_token(token)
      opt_join_results.remove_token(token)
      generator_tracker.remove_token(token)

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
        parent.node_tokens(beta).reject { hidden_token?(_1) }
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
        neg_join_results.for(wme: wme) + parent_neg_join_results_for(wme: wme)
      elsif token
        neg_join_results.for(token: token) + parent_neg_join_results_for(token: token)
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
        opt_join_results.for(wme: wme) + parent_opt_join_results_for(wme: wme)
      elsif token
        opt_join_results.for(token: token) + parent_opt_join_results_for(token: token)
      else
        []
      end
    end

    private def parent_opt_join_results_for(wme: nil, token: nil)
      if parent
        parent.opt_join_results_for(wme: wme, token: token).reject { opt_join_results.hidden?(_1) }
      else
        []
      end
    end

    private def parent_neg_join_results_for(wme: nil, token: nil)
      if parent
        parent.neg_join_results_for(wme: wme, token: token).reject { neg_join_results.hidden?(_1) }
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
        parent.ncc_tokens_for(token).reject { |parent_token|
          hidden_ncc_tokens.key?(token) && hidden_ncc_tokens[token].key?(parent_token)
        }
      else
        []
      end
    end

    private def hidden_wme?(wme)
      hidden_parent_wmes.key?(wme)
    end

    private def hidden_token?(token)
      hidden_parent_tokens.include?(token.object_id)
    end

    private def hide_token(token)
      hidden_parent_tokens.add(token.object_id)
    end

    private def unhide_token(token)
      hidden_parent_tokens.delete(token.object_id)
    end
  end
end
