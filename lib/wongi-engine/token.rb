module Wongi::Engine
  class Token
    attr_reader :children, :wme, :node, :generated_wmes
    attr_accessor :parent

    def initialize(node, token, wme, assignments = {})
      @node = node
      @parent = token
      @wme = wme
      @assignments = assignments
      @children = []
      @deleted = false
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

    def subst(variable, value)
      @assignments[variable] = value if @assignments.key? variable
    end

    def set(variable, value)
      @assignments[variable] = value
    end

    def assignments
      all_assignments
    end

    def [](var)
      a = assignments[var]
      a.respond_to?(:call) ? a.call(self) : a
    end

    def values_at(*vars)
      vars.map { self[_1] }
    end

    def has_var?(x)
      assignments.key? x
    end

    # TODO: ignore assignments?
    def duplicate?(other)
      self.class == other.class &&
        parent.equal?(other.parent) &&
        wme == other.wme &&
        assignments == other.assignments
    end

    def to_s
      str = "TOKEN [ #{object_id} ancestors=#{ancestors.map(&:object_id).map(&:to_s).join('.')} "
      all_assignments.each_pair { |key, value| str << "#{key}=#{value.is_a?(TokenAssignment) ? "#{value.call} (#{value})" : value} " }
      str << "]"
      str
    end

    def inspect
      to_s
    end

    # def destroy
    #   deleted!
    # end

    def dispose!
      # parent.children.delete(self) if parent
      # @parent = nil
      @wme = nil
    end

    # for neg feedback loop protection
    def generated?(wme)
      return true if generated_wmes.any? { |w| w == wme }

      children.any? { |t| t.generated? wme }
    end

    protected

    def all_assignments
      raise "Assignments is not a hash" unless @assignments.is_a?(Hash)

      if @parent
        @parent.assignments.merge @assignments
      else
        @assignments
      end
    end
  end

  class FakeToken < Token
    def initialize(token, wme, assignments) # rubocop:disable Lint/MissingSuper
      @parent = token
      @wme = wme
      @assignments = assignments
      @children = []
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
    end
  end
end
