require 'spec_helper'

describe Wongi::Engine::JoinNode do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "detects activations by the same fact from both sides" do
    production = engine << rule {
      forall {
        has :_, :b, :Z
        has :X, :b, :Z
      }
    }

    engine << [:a, :b, :c]
    expect(production).to have(1).token
  end
end