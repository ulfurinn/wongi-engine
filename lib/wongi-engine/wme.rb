module Wongi::Engine

  class WME < Struct.new( :subject, :predicate, :object )

    attr_reader :rete

    attr_reader :alphas, :tokens, :generating_tokens
    attr_reader :neg_join_results, :opt_join_results

    def initialize s, p, o, r = nil

      @deleted = false
      @alphas = []
      @tokens = []
      @generating_tokens = []
      @neg_join_results = []
      @opt_join_results = []

      @rete = r

      if r
        super( r.import(s), r.import(p), r.import(o) )
      else
        super( s, p, o )
      end

    end

    def import_into r
      self.class.new subject, predicate, object, r
    end

    def dup
      self.class.new subject, predicate, object, rete
    end

    def == other
      subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~ template
      raise "Cannot match a WME against a #{template.class}" unless Template === template
      result = match_member( template, :subject ) & match_member( template, :predicate ) & match_member( template, :object )
      if result.match?
        result
      end
    end

    def manual?
      generating_tokens.empty?
    end

    def generated?
      !manual?
    end

    def deleted?
      @deleted
    end

    def destroy
      return if deleted?
      @deleted = true
      alphas.each { |alpha| alpha.remove self }.clear
      while tokens.first
        tokens.first.delete    # => will remove itself from the array
      end

      destroy_neg_join_results
      destroy_opt_join_results

    end

    def inspect
      "<WME #{subject.inspect} #{predicate.inspect} #{object.inspect}>"
    end

    def to_s
      inspect
    end

    def hash
      @hash ||= array_form.map( &:hash ).hash
    end

    protected

    def array_form
      @array_form ||= [ subject, predicate, object ]
    end

    def destroy_neg_join_results
      neg_join_results.each do |njr|

        token = njr.owner
        results = token.neg_join_results
        results.delete njr

        if results.empty? #&& !rete.in_snapshot?
          token.node.children.each { |beta|
            beta.beta_activate token, nil, { }
          }
        end

      end.clear
    end

    def destroy_opt_join_results
      opt_join_results.each do |ojr|

        token = ojr.owner
        results = token.opt_join_results
        results.delete ojr

        if results.empty?
          token.delete_children
          token.node.children.each { |beta|
            beta.beta_activate token
          }
        end

      end.clear
    end

    def match_member template, member
      result = WMEMatchData.new
      mine = self.send member
      theirs = template.send member
      if theirs == :_ || mine == theirs
        result.match!
      elsif Template.variable? theirs
        result.match!
        result[theirs] = mine
      end
      result
    end

  end

end
