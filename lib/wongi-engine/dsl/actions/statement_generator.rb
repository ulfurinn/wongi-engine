module Wongi::Engine
  class StatementGenerator < Action

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

      # link to rete here to ensure proper linking with token
      wme = WME.new subject, predicate, object, rete

      production.tracer.trace( action: self, wme: wme ) if production.tracer
      if existing = rete.exists?( wme )
        generated = existing.generating_tokens.size
        if generated > 0 && ! token.generated_wmes.include?( existing )
          token.generated_wmes << existing
          existing.generating_tokens << token
        end
      else
        token.generated_wmes << wme
        wme.generating_tokens << token
        # this MUST be done after we link the wme and the token
        # in order for neg rule invalidation to work
        rete << wme
      end

    end

  end
end
