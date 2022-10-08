module Wongi::Engine
  class AlphaIndex
    private attr_reader :pattern
    private attr_reader :index

    def initialize(pattern)
      @pattern = pattern
      @index = Hash.new { |h, k| h[k] = [] }
    end

    def add(wme)
      collection_for_wme(wme).push(wme)
    end

    def remove(wme)
      collection = collection_for_wme(wme)
      collection.delete(wme)
      if collection.empty?
        # release some memory
        index.delete(hashed_key(wme))
      end
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
