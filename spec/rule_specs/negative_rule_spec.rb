require 'spec_helper'

describe "negative rule" do

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  it "should not introduce variables" do

    proc = lambda {

      engine << rule('one-option') {
        forall {
          neg :Foo, :bar, :_
        }
        make {
          action { |tokens|
            raise "This should never get executed #{tokens}"
          }
        }
      }

    }

    proc.should raise_error( Wongi::Engine::DefinitionError )

  end

end
