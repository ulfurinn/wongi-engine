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
      return nil if partition.nil?

      if Template.variable?(partition)
        ->(token) { token[partition] }
      elsif partition.is_a?(Array) && partition.all? { Template.variable?(_1) }
        ->(token) { token.values_at(*partition) }
      else
        partition
      end
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
      return if tokens.find { |t| t.duplicate? token }

      overlay.add_token(token)
      evaluate
    end

    def beta_deactivate(token)
      overlay.remove_token(token)
      beta_deactivate_children(token:)
      evaluate
    end

    def refresh_child(child)
      evaluate(child: child)
    end

    def evaluate(child: nil)
      groups = if partition
        tokens.group_by(&partition).values
      else
        # just a single group of everything
        [tokens]
      end

      groups.each do |tokens|
        aggregated = self.aggregate.call(tokens.map(&self.map))
        assignment = { var => aggregated }
        children = child ? [child] : self.children
        tokens.each do |token|
          # TODO: optimize this to work with a diff of actual changes
          beta_deactivate_children(token:, children:)
          children.each do |beta|
            beta.beta_activate(Token.new(beta, token, nil, assignment))
          end
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
