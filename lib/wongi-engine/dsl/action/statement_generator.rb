module Wongi::Engine
  module DSL::Action
    class StatementGenerator < Base
      def initialize(template)
        super()
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
          if generated.positive? && !token.generated_wmes.include?(existing)
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
        generated = token.generated_wmes.reject(&:manual?)

        wmes_for_deletion = generated.each_with_object([]) do |wme, acc|
          wme.generating_tokens.delete token
          acc << wme if wme.generating_tokens.empty?
        end

        wmes_for_deletion.each do |wme|
          wme.overlay.retract wme, automatic: true
        end
      end
    end
  end
end
