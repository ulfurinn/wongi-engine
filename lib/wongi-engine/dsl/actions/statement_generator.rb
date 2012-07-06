module Wongi::Engine
  class StatementGenerator < Action

    attr_accessor :rete

    def initialize template
      @template = template
    end

    def execute token

      subject = if Template.variable?( @template.subject )
        v = token[ @template.subject ]
        raise "Unbound variable #{@template.subject} in token #{token}" if v.nil?
        v
      else
        @template.subject
      end

      predicate = if Template.variable?( @template.predicate )
        v = token[ @template.predicate ]
        raise "Unbound variable #{@template.predicate} in token #{token}" if v.nil?
        v
      else
        @template.predicate
      end

      object = if Template.variable?( @template.object )
        v = token[ @template.object ]
        raise "Unbound variable #{@template.object} in token #{token}" if v.nil?
        v
      else
        @template.object
      end

      wme = WME.new subject, predicate, object

      production.tracer.trace( action: self, wme: wme ) if production.tracer
      if existing = rete.exists?( wme )
        generated = existing.generating_tokens.size
        if generated > 0 && ! token.generated_wmes.include?( existing )
          token.generated_wmes << existing
          existing.generating_tokens << token
        end
      else
        added = rete << wme
        token.generated_wmes << added
        added.generating_tokens << token
      end

    end

  end
end
