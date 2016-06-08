module Wongi::Engine

  class Token

    include CoreExt

    attr_reader :children
    attr_reader :wme
    attr_reader :node
    attr_reader :overlay
    attr_accessor :owner, :parent
    attr_reader :neg_join_results
    attr_reader :opt_join_results
    attr_reader :ncc_results
    attr_reader :generated_wmes
    attr_predicate :optional
    attr_predicate :deleted

    def initialize node, token, wme, assignments
      @node, @parent, @wme, @assignments = node, token, wme, assignments
      @overlay = wme ? wme.overlay.highest(token.overlay) : (token ? token.overlay : node.rete.default_overlay)
      @children = []
      @deleted = false
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
      token.children << self if token
    end

    def ancestors
      if parent
        parent.ancestors.unshift parent
      else
        []
      end
    end

    def subst variable, value
      @cached_assignments = nil
      if @assignments.has_key? variable
        @assignments[ variable ] = value
      end
    end

    def assignments
      @cached_assignments ||= all_assignments
    end

    def [] var
      if a = assignments[ var ]
        a.respond_to?(:call) ? a.call( self ) : a
      end
    end

    def has_var? x
      assignments.has_key? x
    end

    # TODO ignore assignments?
    def duplicate? other
      self.parent.equal?(other.parent) && @wme.equal?(other.wme) && self.assignments == other.assignments
    end

    def to_s
      str = "TOKEN [ #{object_id} parent=#{parent ? parent.object_id : 'nil'} "
      all_assignments.each_pair { |key, value| str << "#{key} => #{value} " }
      str << "]"
      str
    end

    def destroy
      deleted!
    end

    def dispose!
      parent.children.delete(self) if parent
      neg_join_results.dup.each(&:unlink)
      opt_join_results.dup.each(&:unlink)
      @parent = nil
      @wme = nil
    end

    # for neg feedback loop protection
    def generated? wme
      return true if generated_wmes.any? { |w| w == wme }
      return children.any? { |t| t.generated? wme }
    end

    protected

    def all_assignments
      raise "Assignments is not a hash" unless @assignments.kind_of?( Hash )
      if @parent
        @parent.assignments.merge @assignments
      else
        @assignments
      end
    end

  end

  class FakeToken < Token
    def initialize token, wme, assignments
      @parent, @wme, @assignments = token, wme, assignments
      @children = []
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
    end
  end

end
