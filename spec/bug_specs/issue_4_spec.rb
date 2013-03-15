require 'spec_helper'

describe "issue 4" do

  it "should correctly retract pre-added items from within a rule" do

    engine = Wongi::Engine.create

    10.times{ |i| engine << [i, :is_number, true] }

    engine.rule 'segregate' do
      forall {
        has :Number, :is_number, true
      }
      make {
        action { |token|
          number = token[:Number]
          engine << [number, :is_even, true]
          engine.retract [number, :is_number, true]
        }
      }
    end

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true

    numbers.should be_empty
    evens.should have(10).items

  end

  it "should correctly retract post-added items from within a rule" do

    engine = Wongi::Engine.create

    engine.rule 'segregate' do
      forall {
        has :Number, :is_number, true
      }
      make {
        action { |token|
          number = token[:Number]
          engine << [number, :is_even, true]
          engine.retract [number, :is_number, true]
        }
      }
    end

    10.times{ |i| engine << [i, :is_number, true] }

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true

    numbers.should be_empty
    evens.should have(10).items

  end

  it "should correctly retract later items from within a rule" do

    engine = Wongi::Engine.create

    10.times{ |i| engine << [i, :is_number, true] }

    engine.rule 'segregate' do
      forall {
        has :Number, :is_number, true
      }
      make {
        action { |token|
          number = token[:Number]
          if number % 2 == 0
            engine << [number, :is_even, true]
            engine.retract [number, :is_number, true]
            engine.retract [number + 1, :is_number, true]
          else
            # this should never be reached
            engine << [number, :is_odd, true]
          end
        }
      }
    end

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true
    odds = engine.select :_, :is_odd, true

    numbers.should be_empty
    evens.should have(5).items
    odds.should be_empty

  end


  it "should not lose track when another rule affects a set" do
    engine = Wongi::Engine.create

    10.times{ |i| engine << [i, :is_number, true] }

    engine.rule 'find odds' do
      forall {
        has :Number, :is_number, true
        has :Number, :probably_odd, true
      }
      make {
        action { |token|
          number = token[:Number]
          if number % 2 != 0
            engine << [number, :is_odd, true]
            engine.retract [number, :is_number, true]
          end
        }
      }
    end
    engine.rule 'find evens' do
      forall {
        has :Number, :is_number, true
        neg :Number, :is_odd, true
      }
      make {
        action { |token|
          number = token[:Number]
          if number % 2 == 0
            engine << [number, :is_even, true]
          else
            engine << [number, :probably_odd, true]
          end
        }
      }
    end

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true
    odds = engine.select :_, :is_odd, true

    # numbers.should be_empty
    evens.should have(5).items
    odds.should have(5).items
  end
end
