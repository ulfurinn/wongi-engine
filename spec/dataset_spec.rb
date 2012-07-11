require 'spec_helper'

describe Wongi::Engine::Network do  

  it 'should expose compiled productions' do

    ds = Wongi::Engine::Network.new

    ds << rule('test-rule') {
      forall {
        has 1, 2, 3
      }
    }

    production = ds.productions['test-rule']
    production.should_not be_nil

    production.tokens.should be_empty

    ds << [1, 2, 3]

    production.should have(1).tokens

  end

end
