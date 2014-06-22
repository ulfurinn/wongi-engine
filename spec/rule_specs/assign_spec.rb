require 'spec_helper'

describe "ASSIGN rule" do

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
    @production = ( engine << rule( 'test-rule', &block ) )
  end

  it "should assign simple expressions" do

    test_rule {
      forall {
        assign :X do
          42
        end
      }
    }
    expect(production.size).to eq(1)
    expect(production.tokens.first[:X]).to eq(42)

  end

  it "should be able to access previous assignments" do

    test_rule {
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

end
