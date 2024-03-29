require 'spec_helper'

describe "negative rule" do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "works" do
    prod = engine << rule {
      forall {
        neg :x, :y, :z
      }
    }

    expect(prod).to have(1).tokens

    engine << [:x, :y, 42]
    expect(prod).to have(1).tokens

    engine << %i[x y z]
    expect(prod).to have(0).tokens
  end

  it "does not introduce variables" do
    proc = lambda {
      engine << rule('one-option') {
        forall {
          neg :Foo, :bar, :_
        }
        make {
          action { |tokens|
            raise "This should never get executed #{tokens}"
          }
        }
      }
    }

    expect(&proc).to raise_error(Wongi::Engine::DefinitionError)
  end

  specify "variable example 1" do
    prod = engine << rule {
      forall {
        has :x, :y, :Z
        neg :a, :b, :Z
      }
    }

    engine << [:x, :y, 1]
    expect(prod).to have(1).tokens

    engine << [:a, :b, 1]
    expect(prod).to have(0).tokens
  end

  specify "variable example 1" do
    prod = engine << rule {
      forall {
        has :x, :y, :Z
        neg :a, :b, :Z
      }
    }

    engine << [:a, :b, 1]
    engine << [:x, :y, 1]
    expect(prod).to have(0).tokens

    engine.retract [:a, :b, 1]
    expect(prod).to have(1).tokens
  end

  it "does not create self-negating facts" do
    engine << rule('feedback') {
      forall {
        neg :a, :b, :_
      }
      make {
        gen :a, :b, :c
      }
    }

    expect(engine).to have(0).facts
  end
end
