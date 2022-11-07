require 'spec_helper'

describe Wongi::Engine::EntityIterator do
  let(:engine) { Wongi::Engine.create }

  before do
    engine << [:x, :prop1, 1]
    engine << [:x, :prop2, :y]
    engine << [:y, :prop3, 2]
  end

  it 'returns an enumerator' do
    entity = engine.entity(:x)
    expect(entity.each.to_h).to eq(prop1: 1, prop2: :y)
  end

  it 'iterates over properties' do
    entity = engine.entity(:x)
    results = {}
    entity.each { |k, v| results[k] = v }
    expect(results).to eq(prop1: 1, prop2: :y)
  end

  it 'returns matching values' do
    expect(engine.entity(:x).get_all(:prop1)).to eq([1])
    expect(engine.entity(:x).get_all(:prop2)).to eq([:y])
    expect(engine.entity(:y).get_all(:prop3)).to eq([2])
  end

  it 'can access properties directly' do
    expect(engine.entity(:x).prop1).to eq(1)
    expect(engine.entity(:x).prop2).to eq(:y)
    expect(engine.entity(:y).prop3).to eq(2)
  end
end
