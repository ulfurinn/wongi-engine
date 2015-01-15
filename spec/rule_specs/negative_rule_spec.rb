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

    expect( &proc ).to raise_error( Wongi::Engine::DefinitionError )

  end

  # it "should not create infinite feedback loops by default" do

  #   engine << rule('feedback') {
  #     forall {
  #       neg :a, :b, :_
  #     }
  #     make {
  #       gen :a, :b, :c
  #     }
  #   }

  #   engine.should have(1).facts

  # end

  it "should create infinite feedback loops with unsafe option" do

    counter = 0
    exception = Class.new( StandardError )

    proc = lambda {
      engine << rule('feedback') {
        forall {
          neg :a, :b, :_, unsafe: true
        }
        make {
          action { counter += 1 ; if counter > 5 then raise exception.new end }
          gen :a, :b, :c
        }
      }
    }

    expect( &proc ).to raise_error( exception )

  end

end
