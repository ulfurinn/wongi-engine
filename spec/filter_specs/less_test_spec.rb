require 'spec_helper'

describe "LESS test" do

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

  it "should interact with optional node correctly" do

    # before the fix, filters would try to piggy-back on optional templates

    test_rule {
      forall {
        maybe "Z", "Z", "Z"
        less 6,4 # this should fail
      }

      make {
        gen ".", ".", "."
      }
    }

    engine << ["A", "B", "C"]

    expect(@production.size).to eq(0)
  end

end
