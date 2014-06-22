require "spec_helper"

describe "MAYBE rule" do

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  it "should pass with existing facts" do

    engine << rule('test') do
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    end

    production = engine.productions['test']

    engine << [1, 2, 3]
    engine << [3, 4, 5]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to eq(5)

  end

  it "should pass with missing facts" do

    engine << rule('test') do
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    end

    production = engine.productions['test']

    engine << [1, 2, 3]

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil

  end

  it "should pass with pre-added missing facts" do

    engine << [1, 2, 3]

    engine << rule('test') do
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    end

    production = engine.productions['test']

    expect(production.size).to eq(1)

    expect(production.tokens.first[:X]).to eq(3)
    expect(production.tokens.first[:Y]).to be_nil

  end

end
