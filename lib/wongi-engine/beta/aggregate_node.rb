module Wongi::Engine
  class AggregateNode < BetaNode
    attr_reader :var, :over, :partition, :aggregate, :map

    def initialize(parent, var, over, partition, aggregate, map)
      super(parent)
      @var = var
      @over = over
      @partition = make_partition_fn(partition)
      @aggregate = make_aggregate_fn(aggregate)
      @map = make_map_fn(map)
    end

    def make_partition_fn(partition)
      return nil if partition.empty?

      ->(token) { token.values_at(*partition) }
    end

    def make_aggregate_fn(agg)
      agg
    end

    def make_map_fn(map)
      if map.nil?
        ->(token) { token[over] }
      else
        map
      end
    end

    def beta_activate(token)
      overlay.add_token(token)
      evaluate
    end

    def beta_deactivate(token)
      overlay.remove_token(token)
      beta_deactivate_children(token: token)
      evaluate
    end

    def refresh_child(child)
      evaluate(child: child)
    end

    def evaluate(child: nil)
      return if tokens.empty?

      groups =
        if partition
          tokens.group_by(&partition).values
        else
          # just a single group of everything
          [tokens]
        end

      groups.each do |tokens|
        aggregated = aggregate.call(tokens.map(&map))
        assignment = { var => aggregated }
        children = child ? [child] : self.children
        children.each do |beta|
          new_token = Token.new(beta, tokens, nil, assignment)
          # nothing changed, skip useless traversal
          next if beta.tokens.find { _1.duplicate?(new_token) }

          beta.tokens.select { |child| tokens.any? { child.child_of?(_1) } }.each { beta.beta_deactivate(_1) }
          beta.beta_activate(new_token)
        end
      end
    end

    protected

    def matches?(token, wme)
      @tests.each do |test|
        return false unless test.matches?(token, wme)
      end
      true
    end
  end
end
