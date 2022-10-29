require 'spec_helper'

describe Wongi::Engine::Network do
  include Wongi::Engine::DSL

  subject { engine }

  let(:engine) { Wongi::Engine.create }

  it 'asserts facts' do
    subject << [1, 2, 3]
    expect(subject.select(:_, 2, :_)).to have(1).item
  end

  it 'retracts facts' do
    subject << [1, 2, 3]
    subject.retract [1, 2, 3]
    expect(subject.select(:_, 2, :_).count).to eq(0)
  end

  it 'asserted facts end up in productions' do
    prod = subject << rule { forall { has :X, 2, :Z } }
    subject << [1, 2, 3]
    expect(prod).to have(1).tokens
  end

  it 'rules can be removed from engine' do
    subject << [1, 2, 3]
    subject << [4, 5, 6]

    prod1 = subject << rule { forall { has :X, 2, :Z } }
    prod2 = subject << rule { forall { has :X, 5, :Z } }

    expect(prod1).to have(1).tokens
    expect(prod2).to have(1).tokens

    subject.remove_production(prod1)

    expect(prod1).to have(0).tokens
    expect(prod2).to have(1).tokens
  end

  it 'new rules can be added to engine after a rule has been been removed' do
    subject << [1, 2, 3]
    subject << [4, 5, 6]

    prod1 = subject << rule { forall { has :X, 2, :Z } }

    expect(prod1).to have(1).tokens

    subject.remove_production(prod1)
    expect(prod1).to have(0).tokens

    prod2 = subject << rule { forall { has :X, 5, :Z } }
    expect(prod2).to have(1).tokens
  end

  it 'retracted facts are removed from productions' do
    prod = subject << rule { forall { has :X, 2, :Z } }
    subject << [1, 2, 3]
    subject.retract [1, 2, 3]
    expect(prod).to have(0).tokens
  end

  it 'retracted facts should trigger deactivation' do
    activated_z = nil
    deactivated_z = nil

    subject << rule {
      forall { has :X, 2, :Z }
      make {
        action activate: ->(token) { activated_z = token[:Z] },
               deactivate: ->(token) { deactivated_z = token[:Z] }
      }
    }
    subject << [1, 2, 3]
    expect(activated_z).to be == 3

    subject.retract [1, 2, 3]
    expect(deactivated_z).to be == 3
  end

  it 'retracted facts should propagate through join chains' do
    assignments = nil

    prod = engine << rule {
      forall {
        has :X, :is, :Y
        has :Y, :is, :Z
      }
      make {
        action deactivate: lambda { |token|
          assignments = token.assignments
        }
      }
    }

    engine << [1, :is, 2]
    engine << [2, :is, 3]

    expect(prod).to have(1).tokens

    engine.retract [1, :is, 2]
    expect(prod).to have(0).tokens
    expect(assignments[:X].call).to be == 1
    expect(assignments[:Y].call).to be == 2
    expect(assignments[:Z].call).to be == 3
  end

  it 'retraction should reactivate neg nodes' do
    prod = engine << rule { forall { neg 1, 2, 3 } }

    expect(prod).to have(1).tokens

    engine << [1, 2, 3]
    expect(prod).to have(0).tokens

    engine.retract [1, 2, 3]
    expect(prod).to have(1).tokens
  end

  describe 'retraction with neg nodes lower in the chain' do
    def expect_tokens(n)
      expect(prod).to have(n).tokens
    end

    before do
      engine << rule('retract') {
        forall {
          has :x, :u, :Y
          neg :Y, :w, :_
        }
      }
    end

    let(:prod) { engine.productions['retract'] }

    specify 'case 1' do
      engine << %i[x u y]
      expect_tokens 1

      engine << %i[y w z]
      expect_tokens 0

      engine.retract %i[y w z]
      expect_tokens 1

      engine.retract %i[x u y]
      expect_tokens 0
    end

    specify 'case 2' do
      engine << %i[x u y]
      expect_tokens 1

      engine << %i[y w z]
      expect_tokens 0

      engine.retract %i[x u y]
      expect_tokens 0

      engine.retract %i[y w z]
      expect_tokens 0
    end

    specify 'case 3' do
      engine << %i[y w z]
      expect_tokens 0

      engine << %i[x u y]
      expect_tokens 0

      engine.retract %i[x u y]
      expect_tokens 0

      engine.retract %i[y w z]
      expect_tokens 0
    end

    specify 'case 4' do
      engine << %i[y w z]
      expect_tokens 0

      engine << %i[x u y]
      expect_tokens 0

      engine.retract %i[y w z]
      expect_tokens 1

      engine.retract %i[x u y]
      expect_tokens 0
    end
  end
end
