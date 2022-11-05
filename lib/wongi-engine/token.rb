require 'set'

module Wongi::Engine
  class Token
    attr_reader :wme, :node, :parents

    def initialize(node, parents, wme, assignments = {})
      @node = node
      @parents = Set.new(Array(parents))
      @wme = wme
      @assignments = assignments
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

    protected

    def all_assignments
      parents.each_with_object({}) do |parent, acc|
        acc.merge!(parent.assignments)
      end.merge(@assignments)
    end
  end
end
