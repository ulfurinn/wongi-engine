module Wongi::Engine
  class ExtensionClause

    attr_accessor :name, :action, :rule

    def initialize *args, &block
      @args = args
      @block = block
    end

    def import_into model
      if action.respond_to? :call
        self
      else
        a = action.new *@args, &@block
        a.rule = rule if a.respond_to? :rule=
        a.model = model if a.respond_to? :model=
        a
      end
    rescue Exception => e
      e1 = Exception.new "error defining clause #{name} handled by #{action}: #{e}"
      e1.set_backtrace e.backtrace
      raise e1
    end

    def compile *args
      action.call *args
    end

    def execute *args
      action.call *args
    end

  end
end
