module Wongi::Engine
  module DSL::Action
    class StatementGenerator < BaseAction
      def initialize(template)
        super()
        @template = template
      end

      def execute(token)
        subject, predicate, object = @template.resolve!(token)

        # link to rete here to ensure proper linking with token
        wme = WME.new subject, predicate, object, rete
        wme.manual = false

        production.tracer.trace(action: self, wme: wme) if production.tracer
        if (existing = overlay.find(wme))
          # do not mark purely manual tokens as generated, because a circular rule such as the symmetric friend generator this would cause both sides to become self-sustaining
          # TODO: but this may have to be smarter, because there may be more indirect ways of creating such a situation
          if existing.generating_tokens.any?
            token.generated_wmes << existing
            existing.generating_tokens << token
          end
        else
          token.generated_wmes << wme
          wme.generating_tokens << token
          overlay << wme
        end
      end

      def deexecute(token)
        generated = token.generated_wmes.reject(&:manual?)

        wmes_for_deletion = generated.each_with_object([]) do |wme, acc|
          wme.generating_tokens.delete token
          acc << wme if wme.generating_tokens.empty?
        end

        wmes_for_deletion.each do |wme|
          overlay.retract wme, automatic: true
        end
      end
    end
  end
end
