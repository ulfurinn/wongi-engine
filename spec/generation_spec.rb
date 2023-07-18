require 'spec_helper'

describe Wongi::Engine::DSL::Action::StatementGenerator do
  include Wongi::Engine::DSL
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
    it 'generates facts' do
      engine << %w[Alice relative Bob]
      engine << %w[Bob relative Dwight]

      expect(production).to have(1).token
      expect(engine.find(*%w[Alice relative Dwight])).not_to be_nil
    end

    it 'retracts generated facts' do
      engine << %w[Alice relative Bob]
      engine << %w[Bob relative Dwight]
      engine.retract %w[Bob relative Dwight]

      expect(production).to have(0).tokens
      expect(engine.find(*%w[Alice relative Dwight])).to be_nil
    end

    context 'transitive diamond' do
      before do
        engine << %w[Alice relative Bob]
        engine << %w[Bob relative Dwight]
        engine << %w[Alice relative Claire]
        engine << %w[Claire relative Dwight]
      end

      it 'is created' do
        expect(production).to have(2).tokens
        expect(engine.find(*%w[Alice relative Dwight])).not_to be_nil
      end

      it 'remains after a single retraction' do
        engine.retract %w[Claire relative Dwight]

        expect(production).to have(1).token
        expect(engine.find(*%w[Alice relative Dwight])).not_to be_nil
      end

      it 'is destroyed after both retractions' do
        engine.retract %w[Claire relative Dwight]
        engine.retract %w[Alice relative Bob]

        expect(production).to have(0).tokens
        expect(engine.find(*%w[Alice relative Dwight])).to be_nil
      end
    end
  end

  context "pre-asserted", :pre do
    before do
      engine << ["relative", :transitive, true]
    end

    it_behaves_like 'generation'
  end

  context "post-asserted", :post do
    before do
      production
      engine << ["relative", :transitive, true]
    end

    it_behaves_like 'generation'

    it 'does not retract generated facts marked as manual', :wip do
      engine << %w[Alice relative Bob]
      engine << %w[Bob relative Dwight]
      engine << %w[Alice relative Dwight]
      engine.retract %w[Alice relative Bob]

      expect(production).to have(0).tokens
      expect(engine.find(*%w[Alice relative Dwight])).not_to be_nil
    end

    it 'retracts generated facts unmarked as manual', :wip do
      engine << %w[Alice relative Bob]
      engine << %w[Bob relative Dwight]
      engine << %w[Alice relative Dwight]
      engine.retract %w[Alice relative Dwight]
      engine.retract %w[Alice relative Bob]

      expect(production).to have(0).tokens
      expect(engine.find(*%w[Alice relative Dwight])).to be_nil
    end
  end

  specify do
    engine << rule("r1") {
      forall {
        has :Item, :price_group, :Group
        has :Group, :name, :Name
        has :Group, :base_price, :Price
        # equal :Price, :MaxPrice # -- this is necessary for this to work without token converging
      }
      make {
        gen :Item, :Group, :Price
      }
    }

    engine << rule("r2") {
      forall {
        has :Item, :price_group, :Group
        has :Item, :Group, :Price
      }
      make {
        gen :Item, :price, :Price
      }
    }

    material1 = Object.new
    engine << [:toy, :price_group, material1]
    engine << [material1, :name, :material]
    engine << [material1, :base_price, 100]

    material2 = Object.new
    engine << [:toy, :price_group, material2]
    engine << [material2, :name, :material]
    engine << [material2, :base_price, 200]

    packaging = Object.new
    engine << [:toy, :price_group, packaging]
    engine << [packaging, :name, :packaging]
    engine << [packaging, :base_price, 20]

    expect(engine.productions["r2"]).to have(3).tokens
  end
end
