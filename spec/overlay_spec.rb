require 'spec_helper'

describe Wongi::Engine::DataOverlay do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }

  it 'should be disposable' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
    }
    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
    }
    expect(production).to have(0).tokens
  end

  it 'should generate into correct overlays' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
      make {
        gen :X, 4, 5
      }
    }
    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
      expect(engine.find(3, 4, 5)).not_to be_nil
    }
    expect(production).to have(0).tokens
    expect(engine.find(3, 4, 5)).to be_nil
  end

  it 'works with assignments' do
    production = engine << rule {
      forall {
        has 1, 2, :X
        assign(:Something) { 6 }
      }
      make {
        collect :Something, :stuff
        gen :person, 'stuff', :Something
      }
    }

    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
      expect(engine.find(:person, 'stuff', 6)).not_to be_nil
    }

    expect(production).to have(0).tokens
    expect(engine.find(:_, :_, :_)).to be_nil
  end
end
