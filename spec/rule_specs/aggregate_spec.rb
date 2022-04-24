require 'spec_helper'
require 'securerandom'

describe 'aggregate' do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }
  let(:rule_name) { SecureRandom.alphanumeric(16) }
  let(:production) { engine.productions[rule_name] }

  context 'generic clause' do
    it 'should return a single token' do
      engine << rule(rule_name) do
        forall {
          aggregate :_, :weight, :X, on: :object, function: :min
        }
      end

      expect(production.size).to be == 0

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2

      engine << [:melon, :weight, 15]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2

      engine.retract [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 15

      engine.retract [:melon, :weight, 15]
      expect(production.size).to be == 0
    end
  end

  context 'least' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          least :_, :weight, :X, on: :object
        }
      end

      engine << [:pea, :weight, 2]
      engine << [:apple, :weight, 5]

      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
    end
  end

  context 'min' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          min :_, :weight, :X, on: :object
        }
      end

      engine << [:pea, :weight, 2]
      engine << [:apple, :weight, 5]

      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
    end
  end

  context 'greatest' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          greatest :_, :weight, :X, on: :object
        }
      end

      engine << [:pea, :weight, 2]
      engine << [:apple, :weight, 5]

      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
    end
  end

  context 'max' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          max :_, :weight, :X, on: :object
        }
      end

      engine << [:pea, :weight, 2]
      engine << [:apple, :weight, 5]

      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
    end
  end

end
