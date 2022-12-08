require 'spec_helper'

describe Wongi::Engine::InListTest do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "passes when the value is in the literal list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        in_list :X, [1, 2, 3]
      }
    }

    engine << [1, :is, :value]
    expect(prod.size).to eq(1)
  end

  it "does not when the value is not in the literal list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        in_list :X, [1, 2, 3]
      }
    }

    engine << [0, :is, :value]
    expect(prod.size).to eq(0)
  end

  it "passes when the value is in the variable list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        has :Y, :is, :list
        in_list :X, :Y
      }
    }

    engine << [1, :is, :value]
    engine << [[1, 2, 3], :is, :list]
    expect(prod.size).to eq(1)
  end

  it "does not when the value is not in the variable list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        has :Y, :is, :list
        in_list :X, :Y
      }
    }

    engine << [0, :is, :value]
    engine << [[1, 2, 3], :is, :list]
    expect(prod.size).to eq(0)
  end
end

describe Wongi::Engine::NotInListTest do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it "passes when the value is not in the literal list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        not_in_list :X, [1, 2, 3]
      }
    }

    engine << [0, :is, :value]
    expect(prod.size).to eq(1)
  end

  it "does not when the value is in the literal list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        not_in_list :X, [1, 2, 3]
      }
    }

    engine << [1, :is, :value]
    expect(prod.size).to eq(0)
  end

  it "passes when the value is not in the variable list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        has :Y, :is, :list
        not_in_list :X, :Y
      }
    }

    engine << [0, :is, :value]
    engine << [[1, 2, 3], :is, :list]
    expect(prod.size).to eq(1)
  end

  it "does not when the value is in the variable list" do
    prod = engine << rule {
      forall {
        has :X, :is, :value
        has :Y, :is, :list
        not_in_list :X, :Y
      }
    }

    engine << [1, :is, :value]
    engine << [[1, 2, 3], :is, :list]
    expect(prod.size).to eq(0)
  end
end
