module Wongi::Engine

  class Graph

    def initialize dataset
      @ds = dataset
    end

    def dot io, opts = { }

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

      @io.puts "};"

    ensure
      @io = nil
    end

    private

    def print_hash h
      h.to_s.gsub /-/, '_'
    end

    def dump_alphas opts
      @io.puts "subgraph cluster_alphas {"
      @ds.alphas.select { |alpha| not alpha.betas.empty? }.each do |alpha|
        @io.puts "node#{print_hash alpha.hash} [shape=box label=\"#{alpha.template.to_s.gsub /"/, "\\\""}\"];"
      end
      @io.puts "};"
    end

    def dump_betas opts
      dump_beta @ds.beta_top, opts
    end

    def dump_beta beta, opts
      @io.puts "node#{print_hash beta.hash} [label=\"#{beta.class.name.split('::').last}\"];"
      if beta.parent
        @io.puts "node#{print_hash beta.parent.hash} -> node#{print_hash beta.hash};"
      end
      if beta.is_a? NccNode
        @io.puts "node#{print_hash beta.partner.hash} -> node#{print_hash beta.hash};"
        @io.puts "{ rank=same; node#{print_hash beta.partner.hash} node#{print_hash beta.hash} }"
      end
      if beta.respond_to? :alpha and opts[:alpha] != false
        alpha = beta.alpha
        if alpha
          @io.puts "node#{print_hash alpha.hash} -> node#{print_hash beta.hash};"
        end
      end
      beta.children.each do |child|
        dump_beta child, opts
      end
    end

  end

end
