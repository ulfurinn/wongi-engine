require 'spec_helper'

describe Wongi::Engine::DSL::Action::StatementGenerator do

  let(:engine) { Wongi::Engine.create }

  let(:transitive_rule) {
    rule {
      forall {
        has :P, :transitive, true
        has :X, :P, :Y
        has :Y, :P, :Z
      }
      make {
        gen :X, :P, :Z
      }
    }
  }

  let(:production) { engine << transitive_rule }

  shared_examples 'generation' do

    it 'should generate facts' do
      engine << %w( Alice relative Bob )
      engine << %w( Bob relative Dwight )

      expect(production).to have(1).token
      expect(engine.find *%w( Alice relative Dwight )).not_to be_nil
    end

    it 'should retrct generated facts' do
      engine << %w( Alice relative Bob )
      engine << %w( Bob relative Dwight )
      engine.retract %w( Bob relative Dwight )

      expect(production).to have(0).tokens
      expect(engine.find *%w( Alice relative Dwight )).to be_nil
    end

    context 'transitive diamond' do

      before :each do
        engine << %w( Alice relative Bob )
        engine << %w( Bob relative Dwight )
        engine << %w( Alice relative Claire )
        engine << %w( Claire relative Dwight )
      end

      it 'should be created' do
        expect(production).to have(2).tokens
        expect(engine.find *%w( Alice relative Dwight )).not_to be_nil
      end

      it 'should remain after a single retraction' do
        engine.retract %w( Claire relative Dwight )

        expect(production).to have(1).token
        expect(engine.find *%w( Alice relative Dwight )).not_to be_nil
      end

      it 'should be destroyed after both retractions' do
        engine.retract %w( Claire relative Dwight )
        engine.retract %w( Alice relative Bob )

        expect(production).to have(0).tokens
        expect(engine.find *%w( Alice relative Dwight )).to be_nil
      end

    end

  end

  context "pre-asserted", :pre do

    before :each do
      engine << [ "relative", :transitive, true ]
    end

    it_behaves_like 'generation'

  end

  context "post-asserted", :post do

    before :each do
      production
      engine << [ "relative", :transitive, true ]
    end

    it_behaves_like 'generation'

    it 'should not retract generated facts marked as manual', :wip do
      engine << %w( Alice relative Bob )
      engine << %w( Bob relative Dwight )
      engine << %w( Alice relative Dwight )
      engine.retract %w( Alice relative Bob )

      expect(production).to have(0).tokens
      expect(engine.find *%w( Alice relative Dwight )).not_to be_nil
    end

    it 'should retract generated facts unmarked as manual', :wip do
      engine << %w( Alice relative Bob )
      engine << %w( Bob relative Dwight )
      engine << %w( Alice relative Dwight )
      engine.retract %w( Alice relative Dwight )
      engine.retract %w( Alice relative Bob )

      expect(production).to have(0).tokens
      expect(engine.find *%w( Alice relative Dwight )).to be_nil
    end

  end

end
