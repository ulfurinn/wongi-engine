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

        # link to rete here to ensure proper linking with token
        wme = WME.new subject, predicate, object, rete
        wme.manual = false

        origin = GeneratorOrigin.new(token, self)

        production.tracer.trace(action: self, wme: wme) if production.tracer
        if (existing = overlay.find(wme))
          # do not mark purely manual tokens as generated, because a circular rule such as the symmetric friend generator this would cause both sides to become self-sustaining
          # TODO: but this may have to be smarter, because there may be more indirect ways of creating such a situation
          if existing.generators.any?
            token.generated_wmes << existing
            existing.generators << origin
          end
        else
          token.generated_wmes << wme
          wme.generators << origin
          overlay << wme
        end
      end

      def deexecute(token)
        origin = GeneratorOrigin.new(token, self)

        generated = token.generated_wmes.reject(&:manual?).select { _1.generators.include?(origin) }

        wmes_for_deletion = generated.each_with_object([]) do |wme, acc|
          wme.generators.delete origin
          acc << wme if wme.generators.empty?
        end

        wmes_for_deletion.each do |wme|
          overlay.retract wme, automatic: true
        end
      end
    end
  end
end
