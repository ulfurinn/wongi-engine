module Wongi::Engine
  module Alpha

    # @private
    class Cluster
      attr_reader :rete

      def initialize(rete)
        @rete = rete
        @top = Node.new(rete)
      end

      # @private
      def prepare(template)
        if node = @top.find_node(template)
          return node
        end
        @top.prepare(template)
      end

      def find(template)
        prepare(template)
        rete.current_overlay.all_wmes(@top.find_minimal(template)).first
      end

      def select(template, &block)
        prepare(template)
        rete.current_overlay.all_wmes(@top.find_minimal(template)).select(&block)
      end

      def activate(wme)
        prepare(wme)
        @top.activate(wme)
      end
    end

    # @private
    class Node
      attr_reader :betas

      def initialize(rete)
        @rete = rete
        @betas = []
        @subjects = {}
        @predicates = {}
        @objects = {}
      end

      def wmes(template)
        find_minimal(template).wmes_enum
      end

      def activate(wme)
        rete.current_overlay.add_wme(wme, self)
        @betas.each { |beta| beta.alpha_activate(wme) }
        if sub = @subjects[wme.subject]
          sub.activate(wme)
        end
        if sub = @predicates[wme.predicate]
          sub.activate(wme)
        end
        if sub = @objects[wme.object]
          sub.activate(wme)
        end
      end

      def wmes_enum
        Enumerator.new do |y|
          rete.overlays.each do |overlay|
            overlay.raw_wmes(self).dup.each do |wme|
              y << wme
            end
          end
        end
      end

      def find_minimal(template)
        if template.is_a?(Template) || template.is_a?(WME)
          return find_minimal(template_to_search_spec(template))
        end
        candidates = find_candidates(template).flatten.uniq
        candidates.sort_by { |node| rete.current_overlay.all_wmes(node).length }.first
      end

      def find_candidates(template)
        if template.has_key?(:subject) && child = @subjects[template[:subject]]
          subtemplate = template.dup.tap { |h| h.delete :subject }
          child.find_candidates(subtemplate)
        else
          []
        end +
        if template.has_key?(:predicate) && child = @predicates[template[:predicate]]
          subtemplate = template.dup.tap { |h| h.delete :predicate }
          child.find_candidates(subtemplate)
        else
          []
        end +
        if template.has_key?(:object) && child = @objects[template[:object]]
          subtemplate = template.dup.tap { |h| h.delete :object }
          child.find_candidates(subtemplate)
        else
          []
        end + [self]
      end

      # @private
      def find_node(template)
        if template.is_a?(Template) || template.is_a?(WME)
          return find_node(template_to_search_spec(template))
        end

        if template.empty?
          return self
        end

        if template.has_key?(:subject) && child = @subjects[template[:subject]]
          child.find_node(template.dup.tap { |t| t.delete :subject })
        end ||
        if template.has_key?(:predicate) && child = @predicates[template[:predicate]]
          child.find_node(template.dup.tap { |t| t.delete :predicate })
        end ||
        if template.has_key?(:object) && child = @objects[template[:object]]
          child.find_node(template.dup.tap { |t| t.delete :object })
        end
      end

      # @private
      def prepare(template)
        if template.is_a?(Template) || template.is_a?(WME)
          return prepare(template_to_search_spec(template))
        end

        place_node(Node.new(rete), template)
      end

      # @private
      def place_node(node, template)
        if template.has_key?(:subject)
          subtemplate = template.dup
          subject = subtemplate.delete :subject
          if subtemplate.empty?
            @subjects[subject] ||= node
          else
            @subjects[subject] ||= Node.new(rete)
            @subjects[subject].place_node(node, subtemplate)
          end
        end

        if template.has_key?(:predicate)
          subtemplate = template.dup
          predicate = subtemplate.delete :predicate
          if subtemplate.empty?
            @predicates[predicate] ||= node
          else
            @predicates[predicate] ||= Node.new(rete)
            @predicates[predicate].place_node(node, subtemplate)
          end
        end

        if template.has_key?(:object)
          subtemplate = template.dup
          object = subtemplate.delete :object
          if subtemplate.empty?
            @objects[object] ||= node
          else
            @objects[object] ||= Node.new(rete)
            @objects[object].place_node(node, subtemplate)
          end
        end

        node
      end

      private

      attr_reader :rete

      def template_to_search_spec(template)
        search_spec = {}
        %i(subject predicate object).each do |member|
          if Template.const?(template.send(member))
            search_spec[member] = template.send(member)
          end
        end
        search_spec
      end
    end
  end
end
