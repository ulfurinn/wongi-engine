require 'spec_helper'

describe "ANY rule" do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }

  context 'with two options' do
    let :production do
      engine << rule do
        forall {
          any {
            option {
              has :A, :path1, :_
            }
            option {
              has :A, :path2, :_
            }
          }
        }
      end
    end

    it 'should fire on the first path' do
      engine << [:x, :path1, true]
      expect(production.tokens).to have(1).item
    end

    it 'should fire on the second path' do
      engine << [:x, :path2, true]
      expect(production.tokens).to have(1).item
    end

    it 'should fire twice on both paths at once' do
      engine << [:x, :path1, true]
      engine << [:x, :path2, true]
      expect(production.tokens).to have(2).items
    end
  end
end
