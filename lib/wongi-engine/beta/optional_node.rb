module Wongi
  module Engine

    OptionalJoinResult = Struct.new :owner, :wme

    class OptionalNode < JoinNode

      def right_activate wme
        parent.tokens.each do |token|
          if matches? token, wme
            if token.has_optional?
              token.has_optional = false
              token.delete_children
            end
            propagate_activation(token, wme, collect_assignments(wme))
            jr = OptionalJoinResult.new token, wme
            token.opt_join_results << jr
            wme.opt_join_results << jr
          end
        end
      end

      def left_activate token
        match = false
        alpha.wmes.each do |wme|
          assignments = collect_assignments(wme)
          if matches? token, wme
            match = true
            propagate_activation(token, wme, assignments)
            jr = OptionalJoinResult.new token, wme
            token.opt_join_results << jr
            wme.opt_join_results << jr
          end
        end
        unless match
          token.has_optional = true
          propagate_activation(token, nil, {})
        end
      end

      def refresh_child child
        tmp = children
        self.children = [ child ]
        alpha.wmes.each do |wme|
          right_activate wme
        end
        self.children = tmp
      end

    end
  end
end
