require 'spec_helper'
require 'securerandom'

describe 'aggregate' do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }
  let(:rule_name) { SecureRandom.alphanumeric(16) }
  let(:production) { engine.productions[rule_name] }

  context 'generic clause' do
    it 'returns a single token' do
      engine << rule(rule_name) do
        forall {
          aggregate :_, :weight, :_, on: :object, function: :min, assign: :X
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
          least :_, :weight, :_, on: :object, assign: :X
          has :Fruit, :weight, :X
        }
      end

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea

      engine.retract [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple
    end
  end

  context 'min' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          min :_, :weight, :_, on: :object, assign: :X
          has :Fruit, :weight, :X
        }
      end

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea

      engine.retract [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple
    end
  end

  context 'greatest' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          greatest :_, :weight, :_, on: :object, assign: :X
          has :Fruit, :weight, :X
        }
      end

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea
    end
  end

  context 'max' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          max :_, :weight, :_, on: :object, assign: :X
          has :Fruit, :weight, :X
        }
      end

      engine << [:pea, :weight, 2]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 5
      expect(production.tokens.first[:Fruit]).to be == :apple

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:X]).to be == 2
      expect(production.tokens.first[:Fruit]).to be == :pea
    end
  end

  context 'count' do
    it 'works' do
      engine << rule(rule_name) do
        forall {
          count :_, :weight, :_, assign: :Count
        }
      end

      engine << [:pea, :weight, 1]
      expect(production.size).to be == 1
      expect(production.tokens.first[:Count]).to be == 1

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:Count]).to be == 2

      engine << [:watermelon, :weight, 15]
      expect(production.size).to be == 1
      expect(production.tokens.first[:Count]).to be == 3

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 1
      expect(production.tokens.first[:Count]).to be == 2
    end

    it 'works with a post-filter' do
      engine << rule(rule_name) do
        forall {
          count :_, :weight, :_, assign: :Count
          gte :Count, 3 # pass if at least 3 matching facts exist
        }
      end

      engine << [:pea, :weight, 1]
      expect(production.size).to be == 0

      engine << [:apple, :weight, 5]
      expect(production.size).to be == 0

      engine << [:watermelon, :weight, 15]
      expect(production.size).to be == 1
      expect(production.tokens.first[:Count]).to be == 3

      engine.retract [:apple, :weight, 5]
      expect(production.size).to be == 0
    end
  end
end
