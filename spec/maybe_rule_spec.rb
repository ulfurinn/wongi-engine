require "spec_helper"

describe "MAYBE rule" do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }
  let(:maybe_rule) {
    rule {
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    }
  }

  it "passes with existing facts" do
    production = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to eq(5)
  end

  it "passes with missing facts" do
    production = engine << maybe_rule

    engine << [1, 2, 3]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil
  end

  it "passes with pre-added missing facts" do
    engine << [1, 2, 3]

    production = engine << maybe_rule

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil
  end

  it 'passes with retracted facts' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]
    engine.retract [3, 4, 5]

    expect(prod.size).to eq(1)

    expect(prod.tokens.first[:X]).to eq(3)
    expect(prod.tokens.first[:Y]).to be_nil
  end

  it 'works with repeated activations' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]
    engine.retract [3, 4, 5]

    10.times {
      engine << [3, 4, 5]
      expect(prod.size).to eq(1)
      expect(prod.tokens.first[:Y]).to be == 5

      engine.retract [3, 4, 5]
      expect(prod.size).to eq(1)
      expect(prod.tokens.first[:Y]).to be_nil
    }
  end

  it 'works with with overlays' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]

    engine << [3, 4, 5]
    expect(prod.size).to eq(1)
    expect(prod.tokens.first[:Y]).to be == 5

    engine.with_overlay do |overlay|
      overlay.retract [3, 4, 5]
      expect(prod.size).to eq(1)
      expect(prod.tokens.first[:Y]).to be_nil
    end

    expect(prod.size).to eq(1)
    expect(prod.tokens.first[:Y]).to be == 5
  end

  it 'handles retracted parent tokens' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]
    engine.retract [1, 2, 3]

    expect(prod).to have(0).tokens
    expect(engine.base_overlay.opt_join_results_for(wme: engine.find(3, 4, 5))).to be_empty
  end

  context 'should handle retracted parent tokens with overlays' do
    specify 'variation 1' do
      prod = engine << maybe_rule

      engine << [1, 2, 3]
      engine << [3, 4, 5]

      engine.with_overlay do |overlay|
        engine.retract [1, 2, 3]

        expect(prod).to have(0).tokens
        expect(overlay.opt_join_results_for(wme: engine.find(3, 4, 5))).to be_empty
      end

      expect(prod).to have(1).tokens
      expect(engine.base_overlay.opt_join_results_for(wme: engine.find(3, 4, 5))).not_to be_empty
    end

    specify 'variation 2' do
      prod = engine << maybe_rule

      engine << [1, 2, 3]
      engine << [3, 4, 5]

      engine.with_overlay do |overlay|
        engine.retract [1, 2, 3]
        engine << [3, 4, 5]
        engine.retract [1, 2, 3]

        expect(prod).to have(0).tokens
        expect(overlay.opt_join_results_for(wme: engine.find(3, 4, 5))).to be_empty
      end

      expect(prod).to have(1).tokens
      expect(engine.base_overlay.opt_join_results_for(wme: engine.find(3, 4, 5))).not_to be_empty
    end
  end
end
