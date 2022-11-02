require 'set'

module Wongi::Engine
  class Token
    attr_reader :wme, :node, :generated_wmes, :parents

    def initialize(node, parents, wme, assignments = {})
      @node = node
      @parents = Set.new(Array(parents))
      @wme = wme
      @assignments = assignments
      @deleted = false
      @ncc_results = []
      @generated_wmes = []
    end

    def ancestors
      parents.flat_map(&:ancestors).uniq + parents.to_a
    end

    def child_of?(token)
      parents.include?(token)
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
      instance_of?(other.class) &&
        parents == other.parents &&
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
    # def generated?(wme)
    #   return true if generated_wmes.any? { |w| w == wme }
    #
    #   children.any? { |t| t.generated? wme }
    # end

    protected

    def all_assignments
      parents.each_with_object({}) do |parent, acc|
        acc.merge!(parent.assignments)
      end.merge(@assignments)
    end
  end

  class FakeToken < Token
    def initialize(token, wme, assignments) # rubocop:disable Lint/MissingSuper
      @parent = token
      @wme = wme
      @assignments = assignments
      # @children = []
      @neg_join_results = []
      @opt_join_results = []
      @ncc_results = []
      @generated_wmes = []
    end
  end
end
