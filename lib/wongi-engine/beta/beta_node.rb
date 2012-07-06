module Wongi::Engine

  class BetaNode

    include CoreExt

    attr_writer :rete
    attr_reader :parent
    attr_accessor :children
    attr_predicate :debug

    def initialize parent = nil
      @parent = parent
      @children = []
      if parent
        parent.children << self
      end
    end

    def depth
      @depth ||= if parent.nil?
        0
      else
        parent.depth + 1
      end
    end


    def rete
      if parent
        parent.rete
      else
        @rete
      end
    end

    def beta_memory
      beta = children.find { |node| BetaMemory === node }
      if beta.nil?
        beta = BetaMemory.new self
        beta.update_above
      end
      beta
    end

    def join_node alpha, tests, assignment, alpha_deaf
      existing = children.find{ |node| JoinNode === node && node.equivalent?( alpha, tests, assignment ) }
      return existing if existing

      node = JoinNode.new self, tests, assignment
      node.alpha = alpha
      alpha.betas << node unless alpha_deaf

      node
    end

    def optional_node alpha, tests, assignment, alpha_deaf
      node = OptionalNode.new self, tests, assignment
      node.alpha = alpha
      alpha.betas << node unless alpha_deaf
      node
    end

    def filter_node tests
      node = FilterNode.new self, tests
      node.update_above
      node
    end

    def neg_node alpha, tests, alpha_deaf
      node = NegNode.new self, tests, alpha
      alpha.betas << node unless alpha_deaf
      node.update_above
      node
    end

    def ncc_node condition, earlier, parameters, alpha_deaf
      bottom = network condition.children, earlier, parameters, alpha_deaf
      self.children.each do |node|
        if node.kind_of?( NccNode ) and node.partner.parent == bottom
          return node
        end
      end
      ncc = NccNode.new self
      partner = NccPartner.new bottom.beta_memory
      ncc.partner = partner
      partner.ncc = ncc
      partner.divergent = self
      #    partner.conjuncts = condition.children.size
      ncc.update_above
      partner.update_above
      ncc
    end

    CompilationContext = Struct.new :node, :rete, :earlier, :parameters, :alpha_deaf
    def network conditions, earlier, parameters, alpha_deaf
      # puts "Getting beta subnetwork"
      conditions.inject(CompilationContext.new self, self.rete, earlier, parameters, alpha_deaf) do |context, condition|
        condition.compile context
      end.node
    end

    def update_above
      update_from self.parent
    end

    private

    def propagate_activation token, wme, assignments
      self.children.each do |child|
        child.left_activate token, wme, assignments
      end
    end

    def update_from parent
      case parent

      when BetaMemory
        parent.tokens.each do |token|
          self.left_activate token, nil, {}
        end

      when JoinNode, OptionalNode
        tmp = parent.children
        parent.children = [ self ]
        parent.alpha.wmes.each do |wme|
          parent.right_activate wme
        end
        parent.children = tmp

      when FilterNode
        tmp = parent.children
        parent.children = [ self ]
        parent.parent.tokens.each do |token|
          parent.left_activate token
        end
        parent.children = tmp

      when NegNode
        parent.tokens.each do |token|
          if token.neg_join_results.empty?
            left_activate token, nil, {}
          end
        end
        parent.alpha.wmes.each do |wme|
          parent.right_activate wme
        end

      when NccNode
        parent.tokens.each do |token|
          if token.ncc_results.empty?
            left_activate token, nil, {}
          end
        end

      end # => case
    end
  end

end
