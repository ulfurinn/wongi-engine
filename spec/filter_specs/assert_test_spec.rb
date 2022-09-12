require 'spec_helper'

describe "ASSERT test" do

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  def production
    @production
  end

  def test_rule &block
    @production = (engine << rule('test-rule', &block))
  end

  it "should pass with a constant 'true'" do

    test_rule {
      forall {
        assert { |token|
          true
        }
      }
    }

    expect(production).to have(1).token
    
  end

  it "should fail with a constant 'false'" do

    test_rule {
      forall {
        assert { |token|
          false
        }
      }
    }

    expect(production).to have(0).tokens

  end

  it "should use the token with no arguments" do

    test_rule {
      forall {
        has :X, "is", :Y
        assert { |token|
          token[:X] == "resistance"
        }
      }
    }

    engine << ["resistance", "is", "futile"]

    expect(production).to have(1).token
    expect(production.tokens.first[:X]).to eq("resistance")

  end

  it "should be retractable" do

    test_rule {
      forall {
        has :X, "is", :Y
        assert { |token|
          token[:X] == "resistance"
        }
      }
    }

    engine << ["resistance", "is", "futile"]
    engine.retract ["resistance", "is", "futile"]
    expect(production).to have(0).tokens

  end

  it "should use individual variables with arguments" do

    test_rule {
      forall {
        has :X, "is", :Y
        assert :X, :Y do |x, y|
          y == "futile"
        end
      }
    }

    engine << ["resistance", "is", "futile"]

    expect(production).to have(1).token
    expect(production.tokens.first[:X]).to eq("resistance")

  end

end
