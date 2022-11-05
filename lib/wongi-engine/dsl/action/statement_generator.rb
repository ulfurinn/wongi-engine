require "set"

module Wongi::Engine
  module DSL::Action
    class StatementGenerator < BaseAction
      attr_reader :template
      private :template

      def initialize(template)
        super()
        @template = template
      end

      def execute(token)
        # p execute: {token:}
        subject, predicate, object = template.resolve!(token)

        wme = WME.new(subject, predicate, object)
        wme = overlay.find(wme) || wme

        production.tracer.trace(action: self, wme: wme) if production.tracer

        if should_assert?(wme, token)
          overlay.assert(wme, generator: token)
        end
      end

      private def should_assert?(wme, token)
        considered_tokens = Set.new
        tokens_to_consider = [token]
        until tokens_to_consider.empty?
          token = tokens_to_consider.shift
          considered_tokens.add(token)

          # self-affirming reasoning
          return false if token.wme == wme

          # asserting this WME would invalidate the match
          # TODO: clean up
          return false if token.node.is_a?(NegNode) && wme =~ token.node.alpha.template && token.node.matches?(token, wme) # how much is actually necessary?

          token.parents.each { |parent| tokens_to_consider.push(parent) unless considered_tokens.include?(parent) }

          next unless token.wme

          overlay.generators(token.wme).each do |generating_token|
            tokens_to_consider.push(generating_token) unless considered_tokens.include?(generating_token)
          end
        end

        # we could not prove that the new WME should not be asserted
        true
      end
    end
  end
end
