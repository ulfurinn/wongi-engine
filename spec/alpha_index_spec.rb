require 'rspec'
require 'spec_helper'

describe Wongi::Engine::AlphaIndex do
  let(:index) { described_class.new(pattern) }
  let(:wme) { Wongi::Engine::WME.new(1, 2, 3) }

  # private access
  let(:collection) { index.send(:index) }

  before do
    index.add(wme)
  end

  context 'index by subject' do
    let(:pattern) { %i[subject] }
    let(:key) { hashed_key([1]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  context 'index by predicate' do
    let(:pattern) { %i[predicate] }
    let(:key) { hashed_key([2]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  context 'index by object' do
    let(:pattern) { %i[object] }
    let(:key) { hashed_key([3]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  context 'index by subject and predicate' do
    let(:pattern) { %i[subject predicate] }
    let(:key) { hashed_key([1, 2]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  context 'index by subject and object' do
    let(:pattern) { %i[subject object] }
    let(:key) { hashed_key([1, 3]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  context 'index by predicate and object' do
    let(:pattern) { %i[predicate object] }
    let(:key) { hashed_key([2, 3]) }

    it 'indexes by pattern' do
      expect(collection.keys).to eq([key])
      expect(collection[key]).to eq(Set.new([wme]))
    end
  end

  def hashed_key(key)
    key.map(&:hash)
  end
end
