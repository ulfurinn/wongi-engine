module Wongi::Engine
  module DSL::Action
    class StatementGenerator < BaseAction
      GeneratorOrigin = Struct.new(:token, :action)

      private attr_reader :template
      def initialize(template)
        super()
        @template = template
      end

      def execute(token)
        # p execute: {token:}
        subject, predicate, object = template.resolve!(token)

        wme = WME.new(subject, predicate, object)

        origin = GeneratorOrigin.new(token, self)

        production.tracer.trace(action: self, wme: wme) if production.tracer
        if (existing = overlay.find(wme))
          # do not mark purely manual tokens as generated, because a circular rule such as the symmetric friend generator this would cause both sides to become self-sustaining
          # TODO: but this may have to be smarter, because there may be more indirect ways of creating such a situation
          if overlay.generated?(wme)
            token.generated_wmes << existing
            overlay.assert(existing, generator: origin)
          end
        else
          token.generated_wmes << wme
          overlay.assert(wme, generator: origin)
        end
      end

      def deexecute(token)
        origin = GeneratorOrigin.new(token, self)

        generated = token.generated_wmes.select { overlay.generators(_1).include?(origin) }
        generated.each do |wme|
          overlay.retract wme, generator: origin
        end
      end
    end
  end
end
