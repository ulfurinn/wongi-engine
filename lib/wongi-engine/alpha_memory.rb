module Wongi::Engine

  class AlphaMemory
    attr_reader :betas, :template, :rete

    def initialize(template, rete = nil)
      @template = template
      @rete = rete
      @betas = []
      @wmes = []
      @frozen = false
    end

    def activate(wme)
      wme.overlay.add_wme(wme, self)
      # TODO: it used to activate before adding to the list. mandated by the original thesis. investigate. it appears to create duplicate tokens - needs a remedy in collecting nodes
      betas.each do |beta|
        beta.alpha_activate wme
      end
    end

    def deactivate(wme)
      wme.overlay.remove_wme(wme, self)
      betas.each do |beta|
        beta.alpha_deactivate wme
      end
    end

    def snapshot!(alpha)
      alpha.wmes.map(&:dup).each do |wme|
        activate wme
      end
    end

    def inspect
      "<Alpha #{__id__} template=#{template}>"
    end

    def to_s
      inspect
    end

    def size
      wmes.count
    end

    def wmes
      Enumerator.new do |y|
        rete.overlays.each do |overlay|
          overlay.raw_wmes(self).dup.each do |wme|
            y << wme
          end
        end
      end
    end
  end

end
