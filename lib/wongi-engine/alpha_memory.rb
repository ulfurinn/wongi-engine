module Wongi::Engine

  class AlphaMemory

    attr_reader :betas, :template, :rete, :wmes

    def initialize template, rete = nil
      @template = template
      @rete = rete
      @betas = []
      @wmes = []
      @frozen = false
    end

    def activate wme
      betas.each do |beta|
        beta.alpha_activate wme
      end
      @wmes << wme
      wme.alphas << self
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
      "<Alpha #{__id__} template=#{template} wmes=#{wmes}>"
    end

    def to_s
      inspect
    end

  end

end
