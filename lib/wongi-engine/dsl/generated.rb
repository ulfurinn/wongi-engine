module Wongi::Engine::DSL
  module Generated

    def self.create_dsl_method extension

      section = extension[:section]
      clause = extension[:clause]
      action = extension[:action]
      body = extension[:body]
      acceptor = extension[:accept]

      define_method clause.first do |*args, &block|

        raise "#{clause.first} can only be invoke in section #{section}, currently in #{@current_section}" if section != @current_section

        if body

          instance_exec *args, &body

        elsif acceptor

          accept acceptor.new( *args, &block )

        elsif action

          c = Clause::Generic.new *args, &block
          c.name = clause.first
          c.action = action
          c.rule = self
          accept c

        end

      end

      clause[1..-1].each do |al|
        alias_method al, clause.first
      end

    end

  end
end
