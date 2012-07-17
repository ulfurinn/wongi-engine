require 'spec_helper'

describe "NCC rule" do

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  def ncc_rule
    rule('ncc') {
      forall {
        has "base", "is", :Base
        none {
          has :Base, 2, :X
          has :X, 4, 5
        }
      }
    }
  end

  it 'should pass with a mismatching subchain' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]

    production.should have(1).tokens

    engine << [1, 2, 3]

    production.should have(1).tokens

    engine << [3, 4, 5]

    production.should have(0).tokens

  end

  it 'should remain consistent after retraction' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]
    engine << [1, 2, 3]
    engine << [3, 4, 5]

    production.should have(0).tokens

    engine.retract [3, 4, 5]
    production.should have(1).tokens

    engine.retract ["base", "is", 1]
    production.should have(0).tokens

  end


end
