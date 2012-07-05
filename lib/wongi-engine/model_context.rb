module Wongi
  module Engine

    class ModelContext
      attr_reader :asserted_wmes, :retracted_wmes, :name
      def initialize name
        @name = name
        @asserted_wmes = []
        @retracted_wmes = []
      end
    end
  end
end
