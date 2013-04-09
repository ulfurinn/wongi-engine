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

    prod = engine.productions['test']

    engine << [1, 2, 3]
    engine << [3, 4, 5]

    prod.should have(1).tokens

    prod.tokens.first[:X].should == 3
    prod.tokens.first[:Y].should == 5

  end

  it "should pass with missing facts" do

    engine << rule('test') do
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    end

    prod = engine.productions['test']

    engine << [1, 2, 3]

    prod.should have(1).tokens

    prod.tokens.first[:X].should == 3
    prod.tokens.first[:Y].should be_nil

  end

  it "should pass with pre-added missing facts" do

    engine << [1, 2, 3]

    engine << rule('test') do
      forall {
        has 1, 2, :X
        maybe :X, 4, :Y
      }
    end

    prod = engine.productions['test']

    prod.should have(1).tokens

    prod.tokens.first[:X].should == 3
    prod.tokens.first[:Y].should be_nil

  end

end
