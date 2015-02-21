module Wongi
  module Engine

    OptionalJoinResult = Struct.new :token, :wme do
      def unlink
        wme.opt_join_results.delete self
        token.opt_join_results.delete self
      end
    end

    class OptionalNode < BetaNode

      attr_reader :alpha, :tests, :assignments, :tokens

      def initialize parent, alpha, tests, assignments
        super( parent )
        @alpha = alpha
        @tests = tests
        @assignments = assignments
        @tokens = []
      end

      def make_opt_result token, wme
        jr = OptionalJoinResult.new token, wme
        token.opt_join_results << jr
        wme.opt_join_results << jr
      end

      def alpha_activate wme
        assignments = collect_assignments( wme )
        self.tokens.each do |token|
          if matches? token, wme
            children.each do |child|
              if token.optional?
                token.no_optional!
                child.tokens.select { |ct| ct.parent == token }.each do |ct|
                  child.beta_deactivate ct
                end
              end
              child.beta_activate Token.new( child, token, wme, assignments )
            end
            make_opt_result token, wme
          end
        end
      end

      def alpha_deactivate wme
        wme.opt_join_results.dup.each do |ojr|
          safe_tokens.select { |token| token == ojr.token }.each do |token|
            ojr.unlink
            if token.opt_join_results.empty?
              children.each do |child|
                child.tokens.select { |ct| ct.parent == token }.each do |ct|
                  child.beta_deactivate ct
                end
                token.optional!
                child.beta_activate Token.new( child, token, nil, { } )
              end
            end
          end
        end
      end

      def beta_activate t
        return if @tokens.find { |token| token.parent == t }
        token = Token.new( self, t, nil, { } )
        @tokens << token
        match = false
        alpha.wmes.each do |wme|
          assignments = collect_assignments(wme)
          if matches? token, wme
            match = true
            children.each do |child|
              child.beta_activate Token.new( child, token, wme, assignments )
            end
            make_opt_result token, wme
          end
        end
        unless match
          token.optional!
          children.each do |child|
            child.beta_activate Token.new( child, token, nil, { } )
          end
        end
      end

      def beta_deactivate t
        token = @tokens.find { |token| token.parent == t }
        return unless token
        return unless @tokens.delete token
        token.deleted!
        if token.parent
          token.parent.children.delete token
        end
        token.opt_join_results.each &:unlink
        children.each do |child|
          child.tokens.each do |t|
            if t.parent == token
              child.beta_deactivate t
              #token.destroy
            end
          end
        end
        token
      end

      def refresh_child child
        tmp = children
        self.children = [ child ]
        refresh # do the beta part
        alpha.wmes.each do |wme|
          alpha_activate wme
        end
        self.children = tmp
      end

      def delete_token token
        tokens.delete token
        token.opt_join_results.each do |ojr|
          ojr.wme.opt_join_results.delete ojr
        end
        token.opt_join_results.clear
      end

      private

      def matches? token, wme
        @tests.each do |test|
          return false unless test.matches?( token, wme )
        end
        true
      end

      def collect_assignments wme
        assignments = {}
        return assignments if self.assignments.nil?
        # puts "more assignments"
        [:subject, :predicate, :object].each do |field|
          if self.assignments.send(field) != :_
            #puts "#{self.assignments.send(field)} = #{wme.send(field)}"
            assignments[ self.assignments.send(field) ] = TokenAssignment.new( wme, field )
          end
        end
        assignments
      end

      def safe_tokens
        Enumerator.new do |y|
          @tokens.dup.each do |token|
            y << token unless token.deleted?
          end
        end
      end

    end
  end
end
