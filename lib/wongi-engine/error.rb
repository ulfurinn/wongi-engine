module Wongi::Engine

  class Error < StandardError
  end

  class DefinitionError < Error
  end

  class ReteError
    attr_reader :token, :message

    def initialize(token, message, literate)
      @token = token
      @message = message
      @literate = literate
    end

    def literate?
      @literate
    end
  end

end
