module Wongi
  module Engine
    class OrNode < BetaNode
      attr_reader :parents, :rete

      def initialize(parents)
        super nil
        @parents = parents
        parents.each do |parent|
          parent.children << self
        end
        retes = parents.map(&:rete).uniq
        raise "Cannot combine variants from several Retes" if retes.size > 1

        @rete = retes.first
      end

      def ident
        ids = parents.map(&:id).join ", "
        "<R> #{self.class} #{id}, parents #{ids}"
      end

      def depth
        parents.map(&:depth).max + 1
      end

      def beta_activate(token)
        # p beta_activate: {class: self.class, object_id:, token:}

        overlay.add_token(token)

        children.each do |child|
          child.beta_activate(Token.new(child, token, nil))
        end
      end

      def beta_deactivate(token)
        # p beta_deactivate: {class: self.class, object_id:, token:}
        overlay.remove_token(token)
        beta_deactivate_children(token: token)
      end

      def refresh
        parents.each do |parent|
          parent.refresh_child self
        end
      end

      def refresh_child(child)
        tokens.each do |token|
          child.beta_activate(Token.new(child, token, nil))
        end
      end
    end
  end
end
