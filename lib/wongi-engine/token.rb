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

    def own_assignments
      @assignments
    end

    def assignments
      parents.each_with_object({}) do |parent, acc|
        acc.merge!(parent.assignments)
      end.merge(own_assignments)
    end

    def [](var)
      a = assignment(var)
      a.respond_to?(:call) ? a.call(self) : a
    end

    def values_at(*vars)
      vars.map { self[_1] }
    end

    def assignment(x)
      return @assignments[x] if has_own_var?(x)

      parents.each do |parent|
        a = parent.assignment(x)
        return a if a
      end

      nil
    end

    def has_var?(x)
      has_own_var?(x) || parents.any? { _1.has_var?(x) }
    end

    def has_own_var?(x)
      @assignments.key?(x)
    end

    # TODO: ignore assignments?
    def duplicate?(other)
      instance_of?(other.class) &&
        parents == other.parents &&
        wme == other.wme &&
        own_assignments == other.own_assignments
    end

    def to_s
      str = "TOKEN [ #{object_id} ancestors=#{ancestors.map(&:object_id).map(&:to_s).join('.')} "
      assignments.each_pair { |key, value| str << "#{key}=#{value.is_a?(TokenAssignment) ? "#{value.call} (#{value})" : value} " }
      str << "]"
      str
    end

    def inspect
      to_s
    end
  end
end
