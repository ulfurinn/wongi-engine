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
      overlay << [1,2,3]
      expect(production).to have(1).token
    }
    expect(production).to have(0).tokens
  end

  it 'fails with an assign' do
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
      overlay << [1,2,3]
      expect(production).to have(1).token
    }

    expect(production).to have(0).tokens
  end

end
