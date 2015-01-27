module Wongi::Engine

  class AlphaMemory

    attr_reader :betas, :template, :rete

    def initialize template, rete = nil
      @template = template
      @rete = rete
      @betas = []
      @wmes = []
      @frozen = false
    end

    def activate wme
      @wmes << wme
      wme.alphas << self
      # TODO: it used to activate before adding to the list. mandated by the original thesis. investigate. it appears to create duplicate tokens - needs a remedy in collecting nodes
      betas.each do |beta|
        beta.alpha_activate wme
      end
    end

    def deactivate wme
      @wmes.delete wme
      betas.each do |beta|
        beta.alpha_deactivate wme
      end
    end

    def snapshot! alpha
      alpha.wmes.map( &:dup ).each do |wme|
        activate wme
      end
    end

    def inspect
      "<Alpha #{__id__} template=#{template} wmes=#{@wmes}>"
    end

    def to_s
      inspect
    end

    def wmes
      Enumerator.new do |y|
        @wmes.dup.each do |wme|
          y << wme unless wme.deleted?
        end
      end
    end

  end

end
