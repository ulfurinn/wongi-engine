module Wongi::Engine
  Template = Struct.new(:subject, :predicate, :object) do
    def self.variable?(thing)
      thing.is_a?(Symbol) && thing[0] >= 'A' && thing[0] <= 'Z'
    end

    def self.placeholder?(thing)
      thing.is_a?(Symbol) && thing.start_with?('_')
    end

    def self.concrete?(thing)
      !variable?(thing) && !placeholder?(thing)
    end

    def self.match?(wme_element, template_element)
      return true if variable?(template_element) || placeholder?(template_element)

      wme_element == template_element
    end

    # TODO: reintroduce Network#import when bringing back RDF support

    def root?
      subject == :_ && predicate == :_ && object == :_
    end

    def concrete?
      Template.concrete?(subject) && Template.concrete?(predicate) && Template.concrete?(object)
    end

    def variables
      [].tap do |a|
        a << subject if Template.variable?(subject)
        a << predicate if Template.variable?(predicate)
        a << object if Template.variable?(object)
      end
    end

    def ==(other)
      other.is_a?(Template) && subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~(template)
      case template
      when Template
        (template.subject == :_ || template.subject == subject) &&
          (template.predicate == :_ || template.predicate == predicate) &&
          (template.object == :_ || template.object == object)
      else
        raise Error, "templates can only match other templates"
      end
    end

    def inspect
      "<~#{subject.inspect} #{predicate.inspect} #{object.inspect}>"
    end

    def to_s
      inspect
    end

    def resolve!(token)
      s = if Template.variable?(subject)
            raise DefinitionError, "unbound variable #{subject} in token #{token}" unless token.has_var?(subject)

            token[subject]
          else
            subject
          end
      p = if Template.variable?(predicate)
            raise DefinitionError, "unbound variable #{predicate} in token #{token}" unless token.has_var?(predicate)

            token[predicate]
          else
            predicate
          end
      o = if Template.variable?(object)
            raise DefinitionError, "unbound variable #{object} in token #{token}" unless token.has_var?(object)

            token[object]
          else
            object
          end
      [s, p, o]
    end
  end
end
