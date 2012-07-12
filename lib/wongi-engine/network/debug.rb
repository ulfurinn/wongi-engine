module Wongi::Engine

  module NetworkParts

    module Debug

      def full_wme_dump
        @timeline.each_with_index do |slice, index|
          puts "time #{ index - @timeline.length }"
          slice.each do |key, alpha|
            puts "\t#{alpha.template} -> [#{alpha.wmes.map(&:to_s).join ", "}]"
          end
          puts ""
        end
        puts "time 0"
        alpha_hash.each do |key, alpha|
          puts "\t#{alpha.template} -> [#{alpha.wmes.map(&:to_s).join ", "}]"
        end
      end

    end

  end

end
