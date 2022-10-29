require 'spec_helper'

describe "LESS test" do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  attr_reader :production

  def test_rule(&block)
    @production = (engine << rule('test-rule', &block))
  end

  it "interacts with optional node correctly" do
    # before the fix, filters would try to piggy-back on optional templates

    test_rule {
      forall {
        maybe "Z", "Z", "Z"
        less 6, 4 # this should fail
      }

      make {
        gen ".", ".", "."
      }
    }

    engine << %w[A B C]

    expect(@production.size).to eq(0)
  end
end
