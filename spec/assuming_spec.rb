require 'spec_helper'

describe Wongi::Engine::AssumingClause do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it 'includes base rules' do
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
    result = extended.tokens.to_h { |token| [token[:Z], token[:W]] }
    expect(result).to eq(1 => :a, 2 => :b)
  end

  it 'checks for base rule''s existence' do
    f = lambda {
      engine << rule {
        forall {
          assuming :base
        }
      }
    }

    expect(&f).to raise_error Wongi::Engine::UndefinedBaseRule
  end

  it 'comes first in a rule' do
    f = lambda {
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
