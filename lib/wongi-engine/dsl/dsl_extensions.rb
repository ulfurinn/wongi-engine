module Wongi::Engine
  module DSLExtensions

    def self.create_extension extension

      section = extension[:section]
      clause = extension[:clause]
      action = extension[:action]
      body = extension[:body]
      acceptor = extension[:accept]

      define_method clause.first do |*args, &block|

        raise "#{clause.first} can only be used in section #{section}, currently in #{@current_section}" if section != @current_section

        if body

          body.call *args, &block

        elsif acceptor

          if acceptor.respond_to? :call
            accept acceptor.call( *args, &block )
          else
            accept acceptor.new( *args, &block )
          end

        elsif action

          c = ExtensionClause.new *args, &block
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
