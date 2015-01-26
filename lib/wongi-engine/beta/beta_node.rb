module Wongi::Engine

  class BetaNode

    include CoreExt

    attr_writer :rete
    attr_reader :parent
    attr_accessor :children
    attr_accessor :context
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
      @rete ||= if parent
        parent.rete
      else
        @rete
      end
    end

    def beta_memory
      beta = children.find { |node| BetaMemory === node }
      if beta.nil?
        beta = BetaMemory.new self
        beta.debug = debug?
        beta.refresh
      end
      beta
    end

    def join_node alpha, tests, assignment, filters, alpha_deaf
      existing = children.find{ |node| JoinNode === node && node.equivalent?( alpha, tests, assignment, filters ) }
      return existing if existing

      node = JoinNode.new self, tests, assignment, filters
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

    def filter_node test
      existing = children.find{ |node| FilterNode === node && node.equivalent?( test ) }
      return existing if existing

      node = FilterNode.new self, test
      node.refresh
      node
    end

    def assignment_node variable, body
      node = AssignmentNode.new self, variable, body
      node.refresh
      node
    end

    def neg_node alpha, tests, alpha_deaf, unsafe
      node = NegNode.new self, tests, alpha, unsafe
      alpha.betas << node unless alpha_deaf
      node.refresh
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
      ncc.refresh
      partner.refresh
      ncc
    end

    CompilationContext = Struct.new :node, :rete, :earlier, :parameters, :alpha_deaf do
      def dup
        self.class.new( node, rete, earlier.dup, parameters.dup, alpha_deaf )
      end
    end
    
    def network conditions, earlier, parameters, alpha_deaf
      # puts "Getting beta subnetwork"
      conditions.inject(CompilationContext.new self, self.rete, earlier, parameters, alpha_deaf) do |context, condition|
        condition.compile context
      end.node
    end

    def refresh
      parent.refresh_child self
    end

    def refresh_child node
      raise "#{self.class} must implement refresh_child"
    end

    def delete_token token
      # => noop
    end

    def tokens
      Enumerator.new do |y|
        @tokens.dup.each do |token|
          y << token unless token.deleted?
        end
        @tokens.reject! &:deleted?
      end
    end

    def empty?
      @tokens.empty?
    end

    def size
      @tokens.size
    end
    alias_method :length, :size

    private

    def propagate_activation token, wme, assignments
      self.children.each do |child|
        child.beta_activate token, wme, assignments
      end
    end

    def dp message
      if debug?
        puts "#{indent}#{message}"
      end
    end

    def indent
      '  ' * depth
    end

  end

end
