require 'spec_helper'

describe Wongi::Engine::EntityIterator do
  let(:engine) { Wongi::Engine.create }
  let(:x) { engine.entity(:x) }
  let(:y) { engine.entity(:y) }

  before do
    engine << [:x, :prop1, 1]
    engine << [:x, :prop1, 2]
    engine << [:x, :prop2, :y]
    engine << [:y, :prop3, 3]
  end

  describe "#each" do
    it 'returns an enumerator' do
      expect(x.each.to_h).to eq(prop1: 2, prop2: :y)
    end

    it 'iterates over properties' do
      results = {}
      x.each { |k, v| results[k] = v }
      expect(results).to eq(prop1: 2, prop2: :y)
    end
  end

  describe "#get" do
    specify do
      expect(x.get(:prop1)).to eq(1)
      expect(x.get(:prop2)).to eq(:y)
      expect(x.get(:prop3)).to eq(nil)

      expect(y.get(:prop3)).to eq(3)
    end
  end

  describe "#[]" do
    specify do
      expect(x[:prop1]).to eq(1)
      expect(x[:prop2]).to eq(:y)
      expect(x[:prop3]).to eq(nil)

      expect(y[:prop3]).to eq(3)
    end
  end

  describe "#fetch" do
    specify do
      expect(x.fetch(:prop1)).to eq(1)
      expect(x.fetch(:prop2)).to eq(:y)
      expect(x.fetch(:prop3, 42)).to eq(42)
      expect(x.fetch(:prop3) { 42 }).to eq(42)
      expect { x.fetch(:prop3) }.to raise_error(KeyError)

      expect(y.fetch(:prop3)).to eq(3)
    end
  end

  describe "#get_all" do
    it 'returns all matching values' do
      expect(x.get_all(:prop1)).to eq([1, 2])
      expect(x.get_all(:prop2)).to eq([:y])
      expect(x.get_all(:prop3)).to eq([])

      expect(y.get_all(:prop3)).to eq([3])
    end
  end

  describe "#method_missing" do
    it 'can access properties directly' do
      expect(x.prop1).to eq(1)
      expect(x.prop2).to eq(:y)
      expect { x.prop3 }.to raise_error(NoMethodError)

      expect(y.prop3).to eq(3)
    end
  end

  describe "#respond_to_missing?" do
    specify do
      expect(x.respond_to?(:prop1)).to be true
      expect(x.respond_to?(:prop2)).to be true
      expect(x.respond_to?(:prop3)).to be false

      expect(y.respond_to?(:prop3)).to be true
    end
  end
end
