require 'spec_helper'

describe Wongi::Engine::AssumingClause do
  let(:engine) { Wongi::Engine.create }

  it 'should include base rules' do
    engine << rule(:base) {
      forall {
        has :x, :y, :Z
      }
    }

    extended = engine << rule {
      forall {
        assuming :base
        has :Z, :u, :W
      }
    }

    engine << [:x, :y, 1]
    engine << [:x, :y, 2]
    engine << [1, :u, :a]
    engine << [2, :u, :b]
    result = Hash[ extended.tokens.map { |token| [ token[:Z], token[:W] ] } ]
    expect(result).to eq(1 => :a, 2 => :b)
  end

  it 'should check for base rule\'s existence' do
    f = -> {
      engine << rule {
        forall {
          assuming :base
        }
      }
    }

    expect(&f).to raise_error Wongi::Engine::UndefinedBaseRule
  end

  it 'should come first in a rule' do
    f = -> {
      engine << rule(:base) {
        forall {
          has :x, :y, :Z
        }
      }

      engine << rule {
        forall {
          has :Z, :u, :W
          assuming :base
        }
      }
    }

    expect(&f).to raise_error Wongi::Engine::DefinitionError
    
  end
end
