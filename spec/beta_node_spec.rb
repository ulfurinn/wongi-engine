require 'spec_helper'

describe Wongi::Engine::BetaNode do

  include Wongi::Engine::DSL

  let( :engine ) { Wongi::Engine.create }

  describe '#tokens' do

    it 'should be enumerable' do

      production = engine << rule {
        forall {
          has :x, :y, :Z
        }
      }

      engine << [:x, :y, 1]
      engine << [:x, :y, 2]
      engine << [:x, :y, 3]
      zs = production.tokens.map { |token| token[:Z] }
      expect( zs ).to be == [1, 2, 3]

    end

  end

end
