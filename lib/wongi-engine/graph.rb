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
      io.puts "subgraph cluster_alphas {"
      @rete.alphas.reject { |alpha| alpha.betas.empty? }.each do |alpha|
        io.puts "node#{print_hash alpha.object_id} [shape=box label=\"#{alpha.template.to_s.gsub(/"/, '"')}\"];"
      end
      io.puts "};"
    end

    def dump_betas(io, opts)
      dump_beta(io, @rete.beta_top, opts)
    end

    def dump_beta(io, beta, opts)
      return if @seen_betas.include? beta

      @seen_betas << beta
      io.puts "node#{print_hash beta.object_id} [label=\"#{beta.class.name.split('::').last}\\nid=#{beta.object_id}\"];"
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
  end
end
