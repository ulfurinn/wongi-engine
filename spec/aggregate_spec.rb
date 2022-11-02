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
      production.tokens.each do |token|
        expect(token[:X]).to be == 5
        expect(token[:Fruit]).to be == :apple
      end

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 2
      production.tokens.each do |token|
        expect(token[:X]).to be == 2
        expect(token[:Fruit]).to be == :pea
      end

      engine.retract [:pea, :weight, 2]
      expect(production.size).to be == 1
      production.tokens.each do |token|
        expect(token[:X]).to be == 5
        expect(token[:Fruit]).to be == :apple
      end
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
      production.tokens.each do |token|
        expect(token[:X]).to be == 2
        expect(token[:Fruit]).to be == :pea
      end

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 2
      production.tokens.each do |token|
        expect(token[:X]).to be == 5
        expect(token[:Fruit]).to be == :apple
      end

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      production.tokens.each do |token|
        expect(token[:X]).to be == 2
        expect(token[:Fruit]).to be == :pea
      end
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
      production.tokens.each do |token|
        expect(token[:Count]).to be == 1
      end

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 2
      production.tokens.each do |token|
        expect(token[:Count]).to be == 2
      end

      engine << [:watermelon, :weight, 15]
      expect(production.size).to be == 3
      production.tokens.each do |token|
        expect(token[:Count]).to be == 3
      end

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 2
      production.tokens.each do |token|
        expect(token[:Count]).to be == 2
      end
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
      expect(production.size).to be == 3
      production.tokens.each do |token|
        expect(token[:Count]).to be == 3
      end

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

      expect(production).to have(4).tokens
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

      expect(production).to have(4).tokens
      production.tokens.each do |token|
        expect(token[:Product]).to be_a(Integer)
        expect(token[:Product]).to eq(token[:Number])
      end
    end
  end
end
