require 'spec_helper'

describe "negative rule" do

    before :each do
      @engine = Wongi::Engine.create
    end

    def engine
      @engine
    end

    context "with just one negative option" do

      it "should not get a match" do

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

      end

    end

end
