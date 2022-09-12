require "spec_helper"

describe "MAYBE rule" do
  let(:engine) { Wongi::Engine.create }
  let(:maybe_rule) {
    rule {
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    }
  }

  it "should pass with existing facts" do
    production = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to eq(5)
  end

  it "should pass with missing facts" do
    production = engine << maybe_rule

    engine << [1, 2, 3]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil
  end

  it "should pass with pre-added missing facts" do
    engine << [1, 2, 3]

    production = engine << maybe_rule

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil
  end

  it 'should pass with retracted facts' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]
    engine.retract [3, 4, 5]

    expect(prod.size).to eq(1)

    expect(prod.tokens.first[:X]).to eq(3)
    expect(prod.tokens.first[:Y]).to be_nil
  end

  it 'should work with repeated activations' do
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

  it 'should handle retracted parent tokens' do
    prod = engine << maybe_rule

    engine << [1, 2, 3]
    engine << [3, 4, 5]
    engine.retract [1, 2, 3]

    expect(prod).to have(0).tokens
    expect(engine.find(3, 4, 5).opt_join_results).to be_empty
  end
end
