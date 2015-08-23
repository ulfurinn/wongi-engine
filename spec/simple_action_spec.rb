require 'spec_helper'

describe Wongi::Engine::DSL::Action::SimpleAction do

  before :each do
    @rete = Wongi::Engine::Network.new
  end

  def rete
    @rete
  end

  it 'should work with blocks' do

    count = 0

    rete.rule do
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

    rete << [1, 2, 3]

    expect(count).to eq(1)

    rete << [1, 2, 4]

    expect(count).to eq(2)

  end

end
