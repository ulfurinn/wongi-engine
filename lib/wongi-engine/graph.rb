module Wongi::Engine

  class Graph
    def initialize(rete)
      @rete = rete
    end

    def dot(io, opts = {})
      @seen_betas = []

      if String === io
        File.open io, "w" do |actual_io|
          dot actual_io
        end
        return
      end

      @io = io

      @io.puts "digraph {"

      dump_alphas(opts) unless opts[:alpha] == false
      dump_betas(opts)

      @io.puts "}"

    ensure
      @io = nil
    end

    private

    def print_hash h
      h.to_s.gsub /-/, '_'
    end

    def dump_alphas(_opts)
      @io.puts "subgraph cluster_alphas {"
      @rete.alphas.select { |alpha| not alpha.betas.empty? }.each do |alpha|
        @io.puts "node#{print_hash alpha.object_id} [shape=box label=\"#{alpha.template.to_s.gsub /"/, "\\\""}\"];"
      end
      @io.puts "};"
    end

    def dump_betas(opts)
      dump_beta @rete.beta_top, opts
    end

    def dump_beta(beta, opts)
      return if @seen_betas.include? beta

      @seen_betas << beta
      @io.puts "node#{print_hash beta.object_id} [label=\"#{beta.class.name.split('::').last}\"];"
      if beta.is_a? NccNode
        @io.puts "node#{print_hash beta.partner.object_id} -> node#{print_hash beta.object_id};"
        @io.puts "{ rank=same; node#{print_hash beta.partner.object_id} node#{print_hash beta.object_id} }"
      end
      if beta.respond_to? :alpha and opts[:alpha] != false
        alpha = beta.alpha
        @io.puts "node#{print_hash alpha.object_id} -> node#{print_hash beta.object_id};" if alpha
      end
      beta.children.each do |child|
        @io.puts "node#{print_hash beta.object_id} -> node#{print_hash child.object_id};"
        dump_beta child, opts
      end
    end
  end

end
