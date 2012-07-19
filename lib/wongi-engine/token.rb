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
        parent.wmes + (wme ? [wme] : [])
      else
        wme ? [wme] : []
      end
    end

    def delete
      delete_children
      @node.tokens.delete self unless @node.kind_of?( NccPartner )
      @wme.tokens.delete self if @wme
      @parent.children.delete self if @parent

      retract_generated

      @node.delete_token self
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
