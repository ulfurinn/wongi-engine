module Wongi::Engine
  module NetworkParts
    module Debug
      def full_wme_dump
        alpha_hash.each do |_key, alpha|
          puts "\t#{alpha.template} -> [#{alpha.wmes.map(&:to_s).join ', '}]"
        end
      end

      def full_dump(io = $stdout)
        alpha_hash.each_value do |alpha|
          io.puts "ALPHA #{alpha.template}"
          alpha.wmes.each do |wme|
            dump_wme wme, io
          end
        end
        dump_beta beta_top, io
      end

      private

      def token_lineage(token)
        result = []
        while token.parent
          result << token.parent
          token = token.parent
        end
        result
      end

      def dump_wme(wme, io)
        io.puts "\tWME: #{wme.object_id} #{wme}"
        wme.tokens.each { |token| io.puts "\t\tTOKEN #{token.object_id}" }
        io.puts "\tGENERATING:" unless wme.generators.empty?
        wme.generators.each { |token| io.puts "\t\tTOKEN #{token.object_id}" }
      end

      def dump_beta(beta, io)
        case beta
        when BetaMemory
          dump_beta_memory beta, io
        when NccNode
          dump_ncc beta, io
        else
          io.puts "BETA #{beta.object_id} #{beta.class} : TODO"

        end
        io.puts "\tCHILDREN: #{beta.children.map(&:object_id).join ', '}"
        beta.children.each { |child| dump_beta child, io } unless beta.children.empty?
      end

      def dump_beta_memory(beta, io)
        io.puts "BETA MEMORY #{beta.object_id}"
        beta.tokens.each { |token|
          io.puts "\tTOKEN #{token.object_id} [#{token_lineage(token).map(&:object_id).map(&:to_s).join(' - ')}]"
          token.wmes.each { |wme| io.puts "\t\tWME #{wme.object_id}" }
        }
      end

      def dump_ncc(beta, io)
        io.puts "NCC #{beta.object_id}"
        beta.tokens.each { |token|
          io.puts "\tTOKEN #{token.object_id} [#{token_lineage(token).map(&:object_id).map(&:to_s).join(' - ')}]"
          token.wmes.each { |wme| io.puts "\t\tWME #{wme.object_id}" }
        }
      end
    end
  end
end
