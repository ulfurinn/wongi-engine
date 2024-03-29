require 'spec_helper'

describe Wongi::Engine::Network do
  include Wongi::Engine::DSL
  it 'exposes compiled productions' do
    ds = Wongi::Engine.create

    ds << rule('test-rule') {
      forall {
        has 1, 2, 3
      }
    }

    production = ds.productions['test-rule']
    expect(production).not_to be_nil

    expect(production).to be_empty

    ds << [1, 2, 3]

    expect(production.size).to eq(1)
    expect(production.size).to be == 1
  end
end
