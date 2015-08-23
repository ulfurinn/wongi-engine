module Wongi
  module Engine
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
