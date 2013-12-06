module Wongi
  module Engine
    class AnySet

      attr_reader :variants
      def initialize variants
        @variants = variants
      end

      def compile context
        added = []
        branches = variants.map do |variant|
          ctx = BetaNode::CompilationContext.new context.node, context.rete, context.earlier.dup, context.parameters, context.alpha_deaf
          members = context.earlier.size
          variant.compile ctx
          added += ctx.earlier[ (members - ctx.earlier.size) .. -1 ]  # newly added elements
          ctx.node
        end
        context.earlier += added
        context.node = OrNode.new( branches )
        context.node.refresh
        context
      end

    end

    class VariantSet

      attr_reader :children
      def initialize conditions
        @children = conditions
      end

      def compile context
        context.node = context.node.beta_memory.network( children, context.earlier, context.parameters, false )
        context.earlier << self
        context
      end

      def introduces_variable? var
        children.any? { |c|
          if c.kind_of?( VariantSet )
            c.introduces_variable?( var )
          else
            ! c.kind_of?( NegTemplate ) and c.contains?( var )
          end
        }
      end

    end

    class OrNode < BetaMemory

      attr_reader :parents
      attr_reader :rete

      def initialize parents
        super nil
        @parents = parents
        parents.each do |parent|
          parent.children << self
        end
        retes = parents.map( &:rete ).uniq
        raise "Cannot combine variants from several Retes" if retes.size > 1
        @rete = retes.first
      end

      def ident
        ids = parents.map( &:id ).join ", "
        "<R> #{self.class} #{id}, parents #{ids}"
      end


      def depth
        parents.map( &:depth ).max + 1
      end

      def refresh
        parents.each do |parent|
          parent.refresh_child self
        end
      end

    end
  end
end
