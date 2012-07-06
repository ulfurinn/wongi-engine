module Wongi::Engine
  module DatasetParts

    module Collectable

      def collectors name = nil
        @collectors ||= { }
        if name
          @collectors[name] ||= [ ]
        else
          @collectors
        end
      end

      def error_collectors
        collectors :error
      end

      def add_collector collector, name
        collectors( name ) << collector
      end

      def add_error_collector
        add_collector collector, :error
      end

      def collection name
        collectors( name ).map( &:default_collect ).flatten
      end

      def errors
        error_collectors.map( &:errors ).flatten
      end

      def collected_tokens name
        collectors( name ).map { |collector| collector.production.tokens }.flatten
      end

    end

  end
end
