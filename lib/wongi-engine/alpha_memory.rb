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

    def remove wme
      @wmes.delete wme
      # we don't need to unlink ourselves from the wme
      # because this is only called from WME#destroy
      # so the wme will take care of it itself
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
        copy = @wmes.dup
        @wmes.reject! &:deleted?
        copy.each do |wme|
          y << wme unless wme.deleted?
        end
        @wmes.reject! &:deleted?
      end
    end

  end

end
