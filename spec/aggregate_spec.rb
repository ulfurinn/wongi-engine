require 'spec_helper'
require 'securerandom'

describe 'aggregate' do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }
  let(:rule_name) { SecureRandom.alphanumeric(16) }
  let(:production) { engine.productions[rule_name] }

  context 'min' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          has :_, :weight, :Weight
          min :X, over: :Weight
          has :Fruit, :weight, :X
        }
      end

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 5
      expect(token[:Fruit]).to be == :apple

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 2
      expect(token[:Fruit]).to be == :pea

      engine.retract [:pea, :weight, 2]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 5
      expect(token[:Fruit]).to be == :apple
    end
  end

  context 'max' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          has :_, :weight, :Weight
          max :X, over: :Weight
          has :Fruit, :weight, :X
        }
      end

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 2
      expect(token[:Fruit]).to be == :pea

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 5
      expect(token[:Fruit]).to be == :apple

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:X]).to be == 2
      expect(token[:Fruit]).to be == :pea
    end
  end

  context 'count' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          has :_, :weight, :Weight
          count :Count
        }
      end

      engine << [:pea, :weight, 1]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:Count]).to be == 1

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:Count]).to be == 2

      engine << [:watermelon, :weight, 15]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:Count]).to be == 3

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:Count]).to be == 2
    end

    it 'works with a post-filter' do
      engine << rule(rule_name) do
        forall {
          has :_, :weight, :Weight
          count :Count
          gte :Count, 3 # pass if at least 3 matching facts exist
        }
      end

      engine << [:pea, :weight, 1]
      expect(production.size).to be == 0

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 0

      engine << [:watermelon, :weight, 15]
      expect(production.size).to be == 1
      token = production.tokens.first
      expect(token[:Count]).to be == 3

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 0
    end
  end

  context 'partitioning by a single var' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          has :factor, :Number, :Factor
          product :Product, over: :Factor, partition: :Number
        }
      end

      engine << [:factor, 10, 2]
      engine << [:factor, 10, 5]
      engine << [:factor, 12, 3]
      engine << [:factor, 12, 4]

      expect(production).to have(2).tokens
      production.tokens.each do |token|
        expect(token[:Product]).to be_a(Integer)
        expect(token[:Product]).to eq(token[:Number])
      end
    end
  end

  context 'partitioning by a list' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          has :factor, :Number, :Factor
          product :Product, over: :Factor, partition: [:Number]
        }
      end

      engine << [:factor, 10, 2]
      engine << [:factor, 10, 5]
      engine << [:factor, 12, 3]
      engine << [:factor, 12, 4]

      expect(production).to have(2).tokens
      production.tokens.each do |token|
        expect(token[:Product]).to be_a(Integer)
        expect(token[:Product]).to eq(token[:Number])
      end
    end
  end

  it 'propagates a single token' do
    engine << rule {
      forall {
        has :Item, :price_group, :Group
        has :Group, :name, :Name
        has :Group, :base_price, :Price
        max :MaxPrice, over: :Price, partition: %i[Item Name]
        # equal :Price, :MaxPrice # -- this is necessary for this to work without token converging
      }
      make {
        gen :Group, :price, :MaxPrice
      }
    }

    engine << rule("sum") {
      forall {
        has :Item, :price_group, :Group
        has :Group, :price, :Price
        sum :TotalPrice, over: :Price, partition: :Item
      }
      make {
        gen :Item, :price, :TotalPrice
      }
    }

    material1 = Object.new
    engine << [:toy, :price_group, material1]
    engine << [material1, :name, :material]
    engine << [material1, :base_price, 100]

    material2 = Object.new
    engine << [:toy, :price_group, material2]
    engine << [material2, :name, :material]
    engine << [material2, :base_price, 200]

    packaging = Object.new
    engine << [:toy, :price_group, packaging]
    engine << [packaging, :name, :packaging]
    engine << [packaging, :base_price, 20]

    total_price = engine.select(:toy, :price, :_).first
    expect(total_price.object).to eq(220)
  end
end
