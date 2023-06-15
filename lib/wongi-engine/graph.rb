module Wongi::Engine
  class Graph
    def initialize(rete)
      @rete = rete
    end

    def dot(io, opts = {})
      @seen_betas = []

      if io.is_a?(String)
        File.open io, "w" do |actual_io|
          dot actual_io
        end
        return
      end

      io.puts "digraph {"

      dump_alphas(io) unless opts[:alpha] == false
      dump_betas(io, opts)

      io.puts "}"
    end

    private

    def print_hash(h)
      h.to_s.gsub(/-/, '_')
    end

    def dump_alphas(io)
      @rete.alphas.reject { |alpha| alpha.betas.empty? }.each do |alpha|
        io.puts "node#{print_hash alpha.object_id} [shape=box style=filled fillcolor=olivedrab1 label=#{alpha_label(alpha).dump}];"
      end
    end

    def dump_betas(io, opts)
      @rete.beta_top.children.each do |child|
        dump_beta(io, child, opts)
      end
    end

    def dump_beta(io, beta, opts)
      return if @seen_betas.include? beta

      @seen_betas << beta
      io.puts "node#{print_hash beta.object_id} [style=filled fillcolor=#{beta_fillcolor(beta)} label=#{beta_label(beta).dump}];"
      if beta.is_a? NccNode
        io.puts "node#{print_hash beta.partner.object_id} -> node#{print_hash beta.object_id};"
        io.puts "{ rank=same; node#{print_hash beta.partner.object_id} node#{print_hash beta.object_id} }"
      end
      if beta.respond_to?(:alpha) && opts[:alpha] != false
        alpha = beta.alpha
        io.puts "node#{print_hash alpha.object_id} -> node#{print_hash beta.object_id};" if alpha
      end
      beta.children.each do |child|
        io.puts "node#{print_hash beta.object_id} -> node#{print_hash child.object_id};"
        dump_beta(io, child, opts)
      end
    end

    def alpha_label(node)
      node.template.to_s
    end

    def beta_label(node)
      label = node.class.name.split('::').last
      label += "\n" +
        case node
        when JoinNode, NegNode, OptionalNode
          node.alpha.template.to_s
        when FilterNode
          node.test.to_s
        when AssignmentNode
          "#{node.variable} := #{node.body.respond_to?(:call) ? '<dynamic>' : node.body}"
        when ProductionNode
          node.name
        else
          ""
        end

      label
    end

    def beta_fillcolor(node)
      case node
      when JoinNode
        "lightgreen"
      when NegNode
        "lightpink"
      when OptionalNode
        "palegreen"
      when FilterNode
        "lightblue"
      when AssignmentNode
        "lightyellow"
      when ProductionNode
        "lightcoral"
      else
        "white"
      end
    end
  end
end
