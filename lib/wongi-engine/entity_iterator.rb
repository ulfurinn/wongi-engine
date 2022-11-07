module Wongi::Engine
  class EntityIterator

    attr_reader :entity, :collection
    private :entity, :collection

    def initialize(entity, collection)
      @entity = entity
      @collection = collection
    end

    def each
      if block_given?
        @collection.each do |wme|
          yield wme.predicate, wme.object
        end
      else
        Enumerator.new do |y|
          @collection.each do |wme|
            y << [wme.predicate, wme.object]
          end
        end
      end
    end

    def get_all(name)
      each.filter_map { |k, v| v if k == name }
    end

    def method_missing(name)
      each { |k, v| return v if k == name }
      super
    end
  end
end
