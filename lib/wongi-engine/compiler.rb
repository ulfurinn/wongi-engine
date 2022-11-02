module Wongi::Engine
  Compiler = Struct.new(:rete, :node, :conditions, :parameters, :alpha_deaf) do
    def compile
      conditions.inject(self) do |context, condition|
        condition.compile context
      end.node
    end

    def declares_variable?(v)
      parameters.include?(v) || declared_variables.include?(v)
    end

    def declare(v)
      declared_variables << v unless declared_variables.include?(v)
    end

    def declared_variables
      @declared_variables ||= []
    end

    def dup
      Compiler.new(rete, node, conditions, parameters, alpha_deaf).tap do |compiler|
        declared_variables.each { |v| compiler.declare(v) }
      end
    end

    def assignment_node(variable, body)
      self.node = AssignmentNode.new(node, variable, body).tap(&:refresh)
      declare(variable)
    end

    def join_node(condition, tests, assignment)
      alpha = rete.compile_alpha(condition)
      self.node = if (existing = node.children.find { |n| n.is_a?(JoinNode) && n.equivalent?(alpha, tests, assignment) && !n.children.map(&:class).include?(Wongi::Engine::OrNode) })
                    existing
                  else
                    JoinNode.new(node, tests, assignment).tap do |join|
                      join.alpha = alpha
                      alpha.betas << join unless alpha_deaf
                    end
                  end
      node.tap(&:refresh)
    end

    def neg_node(condition, tests)
      alpha = rete.compile_alpha(condition)
      self.node = NegNode.new(node, tests, alpha).tap do |node|
        alpha.betas << node unless alpha_deaf
        node.refresh
      end
    end

    def opt_node(condition, tests, assignment)
      alpha = rete.compile_alpha(condition)
      self.node = OptionalNode.new(node, alpha, tests, assignment).tap do |node|
        alpha.betas << node unless alpha_deaf
        node.refresh
      end
    end

    def aggregate_node(var, over, partition, aggregate, map)
      declare(var)
      self.node = AggregateNode.new(node, var, over, partition, aggregate, map).tap(&:refresh)
    end

    def or_node(variants)
      subvariables = []
      branches = variants.map do |variant|
        subcompiler = Compiler.new(rete, node, variant.conditions, parameters, false)
        declared_variables.each { |v| subcompiler.declare(v) }
        subcompiler.compile
        subvariables << subcompiler.declared_variables
        subcompiler.node
      end
      subvariables.each do |variables|
        variables.each do |v|
          declare(v)
        end
      end
      self.node = OrNode.new(branches).tap(&:refresh)
    end

    def ncc_node(subrule, alpha_deaf)
      subcompiler = Compiler.new(rete, node, subrule.conditions, parameters, alpha_deaf)
      declared_variables.each { |v| subcompiler.declare(v) }
      bottom = subcompiler.compile
      if (existing = node.children.find { |n| n.is_a?(NccNode) && n.partner.parent == bottom })
        self.node = existing
        return
      end
      ncc = NccNode.new(node)
      partner = NccPartner.new(subcompiler.node)
      ncc.partner = partner
      partner.ncc = ncc
      partner.divergent = node
      #    partner.conjuncts = condition.children.size
      ncc.refresh
      partner.refresh
      self.node = ncc
    end

    def filter_node(filter)
      self.node = FilterNode.new(node, filter).tap(&:refresh)
    end
  end
end
