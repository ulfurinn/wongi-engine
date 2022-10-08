module Wongi::Engine
  module DSL::Action
    class SimpleAction < BaseAction
      def initialize(action = nil, *args, &block)
        super()
        @args = args
        case action
        when Class
          @action = @deaction = @reaction = action.new(*args, &block)
        when Hash
          @action = instance_or_proc action[:activate]
          @deaction = instance_or_proc action[:deactivate]
          @reaction = instance_or_proc action[:reactivate]
        end
        @action ||= block
      end

      def execute(token)
        return unless @action

        if @action.is_a?(Proc) || @action.respond_to?(:to_proc)
          rete.instance_exec token, &@action
        elsif @action.respond_to? :call
          @action.call token
        elsif @action.respond_to? :execute
          @action.execute token
        end
      end

      def deexecute(token)
        return unless @deaction

        if @deaction.is_a?(Proc) || @deaction.respond_to?(:to_proc)
          rete.instance_exec token, &@deaction
        elsif @deaction.respond_to? :call
          @deaction.call token
        elsif @deaction.respond_to? :deexecute
          @deaction.deexecute token
        end
      end

      def reexecute(token, newtoken)
        return unless @reaction

        if @reaction.is_a?(Proc) || @reaction.respond_to?(:to_proc)
          rete.instance_exec token, newtoken, &@reaction
        elsif @reaction.respond_to? :call
          @reaction.call token, newtoken
        elsif @reaction.respond_to? :reexecute
          @reaction.reexecute token, newtoken
        end
      end

      def instance_or_proc(thing)
        case thing
        when Class
          thing.new
        when Proc
          thing
        end
      end
    end
  end
end
