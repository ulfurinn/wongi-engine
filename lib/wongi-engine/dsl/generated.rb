module Wongi::Engine::DSL
  module Generated

    module ClassMethods
      def create_dsl_method(extension)

        clause = extension[:clause]
        action = extension[:action]
        body = extension[:body]
        acceptor = extension[:accept]

        define_method clause.first do |*args, &block|

          if body

            instance_exec *args, &body

          elsif acceptor

            rule.accept acceptor.new(*args, &block)

          elsif action

            c = Clause::Generic.new *args, &block
            c.name = clause.first
            c.action = action
            c.rule = self.rule
            rule.accept c

          end

        end

        clause[1..-1].each do |al|
          alias_method al, clause.first
        end

      end
    end

    attr_accessor :rule

    def self.included(base)
      base.extend ClassMethods
    end

  end
end
