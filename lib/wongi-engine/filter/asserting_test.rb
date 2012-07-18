module Wongi::Engine

  class AssertingTest < FilterTest

    def initialize *vars, &body
      @vars = vars
      @body = body
    end

    def passes? token
      if @vars.empty?
        @body.call token
      else
        @body.call *( @vars.map { |var| token[var] } )
      end
    end

  end

end
