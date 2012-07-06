module Wongi::Engine

  class Token

    include CoreExt

    attr_reader :parent, :wme, :children
    attr_accessor :node, :owner
    attr_reader :neg_join_results
    attr_reader :opt_join_results
    attr_reader :ncc_results
    attr_reader :generated_wmes
    attr_predicate :has_optional

    def initialize token, wme, assignments
      @parent, @wme, @assignments = token, wme, assignments
      @children = []
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
      @deexecutors = []
      token.children << self if token
      wme.tokens << self if wme
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
      assignments[ var ]
    end

    def to_s
      str = "TOKEN [\n"
      all_assignments.each_pair { |key, value| str << "\t#{key} => #{value}\n" }
      str << "]"
      str
    end

    def wmes
      if parent
        parent.wmes + [wme]
      else
        [wme]
      end
    end

    def delete preserve_self = false
      delete_children
      # => TODO: why was this last check needed? consult the Rete PhD
      @node.tokens.delete self unless preserve_self# or @node.kind_of?( NccPartner )
      @wme.tokens.delete self if @wme
      @parent.children.delete self if @parent

      retract_generated
      deexecute

      case @node
      when NegNode
        @neg_join_results.each do |njr|
          njr.wme.neg_join_results.delete njr if njr.wme
        end
        @neg_join_results = []

      when OptionalNode
        @opt_join_results.each do |ojr|
          ojr.wme.opt_join_results.delete ojr
        end
        @opt_join_results = []

      when NccNode
        @ncc_results.each do |nccr|
          nccr.wme.tokens.delete nccr
          nccr.parent.children.delete nccr
        end
        @ncc_results = []

      when NccPartner
        @owner.ncc_results.delete self
        if @owner.ncc_results.empty?
          @node.ncc.children.each do |node|
            node.left_activate @owner, nil, {}
          end
        end
      end

    end

    def delete_children
      while @children.first
        @children.first.delete
      end
    end

    protected


    def retract_generated

      @generated_wmes.each do |wme|
        unless wme.manual?  # => TODO: does this ever fail at all?
          wme.generating_tokens.delete self
          if wme.generating_tokens.empty?
            wme.rete.retract wme, true
          end
        end
      end
      @generated_wmes = []

    end

    def deexecute
      @deexecutors.each { |deexec| deexec.deexecute self }
      @deexecutors = []
    end

    def all_assignments
      raise "Assignments is not a hash" unless @assignments.kind_of?( Hash )
      if @parent
        @parent.assignments.merge @assignments
      else
        @assignments
      end
    end

  end

end
