module Wongi::Engine
  class BetaNode
    include CoreExt

    attr_writer :rete
    # @return [Wongi::Engine::BetaNode]
    attr_reader :parent
    attr_accessor :children

    attr_predicate :debug

    def initialize(parent = nil)
      @parent = parent
      @children = []
      parent.children << self if parent
    end

    def root?
      parent.nil?
    end

    def depth
      @depth ||= if parent.nil?
                   0
                 else
                   parent.depth + 1
                 end
    end

    def rete
      @rete ||= (parent.rete if parent)
    end

    abstract :alpha_activate
    abstract :alpha_deactivate
    abstract :alpha_reactivate
    abstract :beta_activate
    abstract :beta_deactivate
    abstract :beta_reactivate
    abstract :refresh_child

    def assignment_node(variable, body)
      node = AssignmentNode.new self, variable, body
      node.refresh
      node
    end

    def refresh
      parent.refresh_child self
    end

    def beta_deactivate_children(token: nil, wme: nil, children: self.children)
      children.each do |child|
        child.tokens.select { (token.nil? || _1.parent == token) && (wme.nil? || _1.wme == wme) }.each do |child_token|
          child.beta_deactivate(child_token)
        end
      end
    end

    private def select_wmes(template)
      rete.current_overlay.select(template)
    end

    def tokens
      overlay.node_tokens(self)
    end

    def overlay
      rete.current_overlay
    end

    def empty?
      tokens.first.nil?
    end

    def size
      tokens.count
    end

    private

    def dp(message)
      puts "#{indent}#{message}" if debug?
    end

    def indent
      '  ' * depth
    end
  end
end
