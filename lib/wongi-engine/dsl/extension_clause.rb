module Wongi::Engine
  class ExtensionClause

    attr_accessor :name, :action, :rule

    def initialize *args, &block
      @args = args
      @block = block
    end

    def import_into rete
      if action.respond_to? :call
        self
      else
        a = action.new *@args, &@block
        a.name = name if a.respond_to? :name=
        a.rule = rule if a.respond_to? :rule=
        a.rete = rete if a.respond_to? :rete=
        a
      end
    rescue StandardError => e
      e1 = StandardError.new "error defining clause #{name} handled by #{action}: #{e}"
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
