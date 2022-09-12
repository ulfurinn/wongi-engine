module Wongi::Engine
  module DSL::Action
    class StatementGenerator < Base
      def initialize(template)
        @template = template
      end

      def execute(token)
        subject, predicate, object = @template.resolve!(token)

        # link to rete here to ensure proper linking with token
        wme = WME.new subject, predicate, object, rete
        wme.manual = false
        wme.overlay = token.overlay

        production.tracer.trace(action: self, wme: wme) if production.tracer
        if (existing = rete.exists?(wme))
          generated = existing.generating_tokens.size
          if generated > 0 && !token.generated_wmes.include?(existing)
            token.generated_wmes << existing
            existing.generating_tokens << token
          end
        else
          token.generated_wmes << wme
          wme.generating_tokens << token
          # this MUST be done after we link the wme and the token
          # in order for neg rule invalidation to work
          wme.overlay.assert wme
        end
      end

      def deexecute(token)
        token.generated_wmes.reject(&:manual?).inject([]) do |list, wme|
          list.tap do |l|
            wme.generating_tokens.delete token
            l << wme if wme.generating_tokens.empty?
          end
        end.each do |wme|
          wme.overlay.retract wme, automatic: true
        end
      end
    end
  end
end
