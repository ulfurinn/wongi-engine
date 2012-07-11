require 'spec_helper'

describe Wongi::Engine::SimpleAction do

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

    count.should == 0

    rete << [1, 2, 3]

    count.should == 1

    rete << [1, 2, 4]

    count.should == 2

  end

end
