module Wongi::Engine
  class DuplicatingEnumerator
    def self.new(collection)
      Enumerator.new do |y|
        collection.dup.each do |e|
          y << e
        end
      end
    end
  end
  class DeleteSafeEnumerator
    def self.new(collection)
      Enumerator.new do |y|
        collection.dup.each do |e|
          y << e unless e.deleted?
        end
        collection.reject! &:deleted?
      end
    end
  end
end
