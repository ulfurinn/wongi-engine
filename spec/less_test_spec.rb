require 'spec_helper'

describe Wongi::Engine::LessThanTest do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "interacts with optional node correctly" do
    # before the fix, filters would try to piggy-back on optional templates

    production = engine << rule {
      forall {
        maybe "Z", "Z", "Z"
        less 6, 4 # this should fail
      }

      make {
        gen ".", ".", "."
      }
    }

    engine << %w[A B C]

    expect(production.size).to eq(0)
  end
end
