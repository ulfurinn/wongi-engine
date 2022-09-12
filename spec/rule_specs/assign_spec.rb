require 'spec_helper'

describe "ASSIGN rule" do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "should assign simple expressions" do
    production = engine << rule {
      forall {
        assign :X do
          42
        end
      }
    }
    expect(production.size).to eq(1)
    expect(production.tokens.first[:X]).to eq(42)
  end

  it 'should be available in the make section' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
      make {
        assign(:Y) { |token| token[:X] * 2 }
        gen :Y, 5, 6
      }
    }
    engine << [1, 2, 21]
    expect(production.tokens.first[:X]).to be == 21
    expect(engine.find(42, 5, 6)).not_to be_nil
    expect(production.tokens.first[:Y]).to be == 42
  end

  it "should be able to access previous assignments" do
    production = engine << rule {
      forall {
        has 1, 2, :X
        assign :Y do |token|
          token[:X] * 2
        end
      }
    }

    engine << [1, 2, 5]
    expect(production.tokens.first[:Y]).to eq(10)
  end

  it 'should be deactivatable' do
    prod = engine << rule {
      forall {
        has 1, 2, :X
        assign :Y do |token|
          token[:X] * 2
        end
      }
    }

    engine << [1, 2, 5]
    engine.retract [1, 2, 5]

    expect(prod).to have(0).tokens
  end

  it 'should be evaluated once' do
    x = 0
    engine << rule {
      forall {
        has :a, :b, :c
        assign :T do
          x += 1
        end
      }
      make {
        gen :d, :e, :T
        gen :f, :g, :T
      }
    }
    engine << %i[a b c]
    expect(x).to be == 1
  end

  xit 'should handle booleans' do
    engine << rule do
      forall {
        has :a, :b, :c
        assign :X do |_token|
          false
        end
      }
      make {
        gen :d, :e, :X
      }
    end
    engine << %i[a b c]
    expect(engine.find(:d, :e, false)).not_to be_nil
  end
end
