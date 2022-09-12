require 'spec_helper'

describe Wongi::Engine::DSL::Action::SimpleAction do
  let(:engine) { Wongi::Engine.create }

  it 'should work with blocks' do
    count = 0

    engine.rule do
      forall {
        has 1, 2, :X
      }
      make {
        action {
          count += 1
        }
      }
    end

    expect(count).to eq(0)

    engine << [1, 2, 3]

    expect(count).to eq(1)

    engine << [1, 2, 4]

    expect(count).to eq(2)
  end
end
