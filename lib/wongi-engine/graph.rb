module Wongi::Engine

  class Graph

    def initialize dataset
      @ds = dataset
    end

    def dot io

      if String === io
        File.open io, "w" do |actual_io|
          dot actual_io
        end
        return
      end

      @io = io

      @io.puts "digraph {"

      dump_alphas
      dump_betas

      @io.puts "};"

    ensure
      @io = nil
    end

    private

    def print_hash h
      h.to_s.gsub /-/, '_'
    end

    def dump_alphas
      @ds.alphas.each do |alpha|
        @io.puts "node#{print_hash alpha.hash} [shape=box label=\"#{alpha.template.to_s.gsub /"/, "\\\""}\"];"
      end
    end

    def dump_betas
      dump_beta @ds.beta_top
    end

    def dump_beta beta
      @io.puts "node#{print_hash beta.hash} [label=\"#{beta.class.name.split('::').last}\"];"
      if beta.parent
        @io.puts "node#{print_hash beta.parent.hash} -> node#{print_hash beta.hash};"
      end
      if beta.respond_to? :alpha
        alpha = beta.alpha
        if alpha
          @io.puts "node#{print_hash alpha.hash} -> node#{print_hash beta.hash};"
        end
      end
      beta.children.each do |child|
        dump_beta child
      end
    end

  end

end
