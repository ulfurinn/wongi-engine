require 'spec_helper'

describe "ASSERT test" do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  attr_reader :production

  def test_rule(&block)
    @production = (engine << rule('test-rule', &block))
  end

  it "passes with a constant 'true'" do
    test_rule {
      forall {
        assert { |_token|
          true
        }
      }
    }

    expect(production).to have(1).token
  end

  it "fails with a constant 'false'" do
    test_rule {
      forall {
        assert { |_token|
          false
        }
      }
    }

    expect(production).to have(0).tokens
  end

  it "uses the token with no arguments" do
    test_rule {
      forall {
        has :X, "is", :Y
        assert { |token|
          token[:X] == "resistance"
        }
      }
    }

    engine << %w[resistance is futile]

    expect(production).to have(1).token
    expect(production.tokens.first[:X]).to eq("resistance")
  end

  it "is retractable" do
    test_rule {
      forall {
        has :X, "is", :Y
        assert { |token|
          token[:X] == "resistance"
        }
      }
    }

    engine << %w[resistance is futile]
    engine.retract %w[resistance is futile]
    expect(production).to have(0).tokens
  end

  it "uses individual variables with arguments" do
    test_rule {
      forall {
        has :X, "is", :Y
        assert :X, :Y do |_x, y|
          y == "futile"
        end
      }
    }

    engine << %w[resistance is futile]

    expect(production).to have(1).token
    expect(production.tokens.first[:X]).to eq("resistance")
  end
end
