module Wongi::Engine

  class WME < Struct.new( :subject, :predicate, :object )

    include CoreExt

    attr_reader :rete

    attr_reader :alphas, :tokens, :generating_tokens
    attr_reader :neg_join_results, :opt_join_results
    attr_predicate :deleted
    attr_predicate :manual

    def initialize s, p, o, r = nil

      manual!

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
      self.class.new( subject, predicate, object, r ).tap do |wme|
        wme.manual = self.manual?
      end
    end

    def dup
      self.class.new( subject, predicate, object, rete ).tap do |wme|
        wme.manual = self.manual?
      end
    end

    def == other
      subject == other.subject && predicate == other.predicate && object == other.object
    end

    def =~ template
      raise Wongi::Engine::Error, "Cannot match a WME against a #{template.class}" unless Template === template
      result = match_member( self.subject, template.subject ) & match_member( self.predicate, template.predicate ) & match_member( self.object, template.object )
      if result.match?
        result
      end
    end

    def generated?
      !generating_tokens.empty?
    end

    # def destroy
    #   return if deleted?
    #   @deleted = true
    #   alphas.each { |alpha| alpha.remove self }.clear
    #   tokens = @tokens
    #   @tokens = []
    #   tokens.each &:destroy

    #   destroy_neg_join_results
    #   destroy_opt_join_results

    # end

    def inspect
      "{#{subject.inspect} #{predicate.inspect} #{object.inspect}}"
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

    # def destroy_neg_join_results
    #   neg_join_results.each do |njr|

    #     token = njr.owner
    #     results = token.neg_join_results
    #     results.delete njr

    #     if results.empty? #&& !rete.in_snapshot?
    #       token.node.children.each { |beta|
    #         beta.beta_activate token, nil, { }
    #       }
    #     end

    #   end.clear
    # end

    # def destroy_opt_join_results
    #   opt_join_results.each do |ojr|

    #     token = ojr.owner
    #     results = token.opt_join_results
    #     results.delete ojr

    #     if results.empty?
    #       token.delete_children
    #       token.node.children.each { |beta|
    #         beta.beta_activate token
    #       }
    #     end

    #   end.clear
    # end

    def match_member mine, theirs
      result = WMEMatchData.new
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
