module Wongi::Engine
  class AlphaIndex
    attr_reader :pattern, :index
    private :pattern
    private :index

    def initialize(pattern)
      @pattern = pattern
      @index = Hash.new { |h, k| h[k] = Set.new }
    end

    def add(wme)
      collection_for_wme(wme).add(wme)
    end

    def remove(wme)
      collection = collection_for_wme(wme)
      collection.delete(wme)

      # release some memory
      index.delete(hashed_key(wme)) if collection.empty?
    end

    def collection_for_wme(wme)
      index[hashed_key(wme)]
    end

    def collections_for_template(template)
      return nil unless template_matches_pattern?(template)

      # here we know that all fields on which we're indexing are concrete in the template
      collection_for_wme(template)
    end

    private def template_matches_pattern?(template)
      template_element_matches_pattern?(:subject, template.subject) &&
      template_element_matches_pattern?(:predicate, template.predicate) &&
      template_element_matches_pattern?(:object, template.object)
    end

    private def template_element_matches_pattern?(member, template_element)
      if Template.concrete?(template_element)
        pattern.include?(member)
      else
        !pattern.include?(member)
      end
    end

    private def key(wme)
      pattern.map { wme.public_send(_1) }
    end

    private def hashed_key(wme)
      key(wme).map(&:hash)
    end
  end
end
