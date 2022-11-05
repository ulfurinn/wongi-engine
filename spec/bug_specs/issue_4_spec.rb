require 'spec_helper'

describe "issue 4" do
  it "correctly retracts pre-added items from within a rule" do
    engine = Wongi::Engine.create

    10.times { |i| engine << [i, :is_number, true] }

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

    expect(numbers.count).to eq(0)
    expect(evens.count).to eq(10)
  end

  it "correctly retracts post-added items from within a rule" do
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

    5.times { |i| engine << [i, :is_number, true] }

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true

    expect(numbers.count).to eq(0)
    expect(evens.count).to eq(5)
  end

  # cascaded processing affects this
  it "does not retract later items from within a rule" do
    engine = Wongi::Engine.create

    10.times { |i| engine << [i, :is_number, true] }

    engine.rule 'segregate' do
      forall {
        has :Number, :is_number, true
      }
      make {
        action { |token|
          number = token[:Number]
          if number.even?
            engine << [number, :is_even, true]
            engine.retract [number, :is_number, true]
            engine.retract [number + 1, :is_number, true]
          else
            # this is not reached without cascades
            engine << [number, :is_odd, true]
          end
        }
      }
    end

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true
    odds = engine.select :_, :is_odd, true

    expect(numbers.count).to eq(0)
    expect(evens.count).to eq(5)
    expect(odds.count).to eq(5)
  end

  it "does not lose track when another rule affects a set" do
    engine = Wongi::Engine.create

    10.times { |i| engine << [i, :is_number, true] }

    engine.rule 'find odds' do
      forall {
        has :Number, :is_number, true
        has :Number, :probably_odd, true
      }
      make {
        action { |token|
          number = token[:Number]
          if number.odd?
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
          engine << if number.even?
                      [number, :is_even, true]
                    else
                      [number, :probably_odd, true]
                    end
        }
      }
    end

    numbers = engine.select :_, :is_number, true
    evens = engine.select :_, :is_even, true
    odds = engine.select :_, :is_odd, true

    expect(numbers.count).to eq(5)
    expect(evens.count).to eq(5)
    expect(odds.count).to eq(5)
  end
end
