require 'spec_helper'
require 'wongi-engine/alpha_index'
require 'wongi-engine/overlay'
require 'wongi-engine/wme'

describe Wongi::Engine::Overlay do
  include Wongi::Engine::DSL

  let(:engine) { Wongi::Engine.create }

  describe "asserting facts" do
    let(:engine) { double(:engine) }
    let(:overlay) { Wongi::Engine::Overlay.new(engine) }

    before do
      # this cannot be put in the double constructor because it causes an infinite recursion
      allow(engine).to receive(:default_overlay).and_return(overlay)
      allow(engine).to receive(:real_assert)
    end

    it 'stores WMEs and retrieves by identity' do
      wmes = [
        Wongi::Engine::WME.new(1, 11, 111),
        Wongi::Engine::WME.new(1, 11, 112),
        Wongi::Engine::WME.new(1, 11, 113),
        Wongi::Engine::WME.new(1, 12, 121),
        Wongi::Engine::WME.new(1, 12, 122),
        Wongi::Engine::WME.new(2, 22, 222),
        Wongi::Engine::WME.new(2, 22, 223),
        Wongi::Engine::WME.new(3, 33, 333),
        Wongi::Engine::WME.new(3, 34, 333),
      ]
      wmes.each { overlay.assert(_1) }

      wmes.each { expect(overlay.find(_1)).to equal(_1) }
    end

    it 'stores WMEs and retrieves by template' do
      wmes = [
        Wongi::Engine::WME.new(1, 11, 111),
        Wongi::Engine::WME.new(1, 11, 112),
        Wongi::Engine::WME.new(1, 11, 113),
        Wongi::Engine::WME.new(1, 12, 121),
        Wongi::Engine::WME.new(1, 12, 122),
        Wongi::Engine::WME.new(2, 11, 111),
        Wongi::Engine::WME.new(2, 11, 222),
        Wongi::Engine::WME.new(2, 22, 222),
        Wongi::Engine::WME.new(2, 22, 223),
        Wongi::Engine::WME.new(3, 33, 113),
        Wongi::Engine::WME.new(3, 33, 333),
        Wongi::Engine::WME.new(3, 34, 333),
      ]
      wmes.each { overlay.assert(_1) }

      expect(overlay.select(1, :_, :_)).to have(5).items
      expect(overlay.select(2, :_, :_)).to have(4).items
      expect(overlay.select(3, :_, :_)).to have(3).items
      expect(overlay.select(1, 11, :_)).to have(3).items
      expect(overlay.select(:_, 11, :_)).to have(5).items
      expect(overlay.select(:_, :_, 113)).to have(2).items
      expect(overlay.select(:_, 22, :_)).to have(2).items
      expect(overlay.select(:_, 22, 222)).to have(1).items
      expect(overlay.select(:_, :_, 222)).to have(2).items
      expect(overlay.select(:_, :_, 223)).to have(1).items

      expect(overlay.select(:_, :_, :_)).to have(wmes.length).items

      expect(overlay.select(1, 11, 111)).to have(1).items
      expect(overlay.select(1, 11, 111).first).to equal(wmes.first)
    end
  end

  context "retracting facts" do
    let(:engine) { double(:engine) }
    let(:overlay) { Wongi::Engine::Overlay.new(engine) }

    before do
      # this cannot be put in the double constructor because it causes an infinite recursion
      allow(engine).to receive(:default_overlay).and_return(overlay)
      allow(engine).to receive(:real_assert)
      allow(engine).to receive(:real_retract)
    end

    it "removes asserted facts" do
      wme = Wongi::Engine::WME.new(1, 11, 111)

      overlay.assert(wme)
      expect(overlay.select(:_, :_, :_)).to have(1).items

      overlay.retract(wme)
      expect(overlay.select(:_, :_, :_)).to have(0).items
    end
  end

  context "layered" do
    let(:engine) { double(:engine) }
    let(:overlay) { Wongi::Engine::Overlay.new(engine) }

    before do
      # this cannot be put in the double constructor because it causes an infinite recursion
      allow(engine).to receive(:default_overlay).and_return(overlay)
      allow(engine).to receive(:real_assert)
      allow(engine).to receive(:real_retract)
    end

    it "maintains visibility on each layer" do
      child1 = overlay.new_child
      child2 = child1.new_child

      wme = Wongi::Engine::WME.new(1, 2, 3)

      overlay.assert(wme)
      expect(overlay.find(wme)).to eq(wme)
      expect(child1.find(wme)).to eq(wme)
      expect(child2.find(wme)).to eq(wme)

      child1.retract(wme)
      expect(overlay.find(wme)).to eq(wme)
      expect(child1.find(wme)).to be_nil
      expect(child2.find(wme)).to be_nil

      child2.assert(wme)
      expect(overlay.find(wme)).to eq(wme)
      expect(child1.find(wme)).to be_nil
      expect(child2.find(wme)).to eq(wme)

      child2.retract(wme)
      expect(overlay.find(wme)).to eq(wme)
      expect(child1.find(wme)).to be_nil
      expect(child2.find(wme)).to be_nil

      child1.assert(wme)
      expect(overlay.find(wme)).to eq(wme)
      expect(child1.find(wme)).to eq(wme)
      expect(child2.find(wme)).to eq(wme)

      overlay.retract(wme)
      expect(overlay.find(wme)).to be_nil
      expect(child1.find(wme)).to be_nil
      expect(child2.find(wme)).to be_nil

      child1.assert(wme)
      expect(overlay.find(wme)).to be_nil
      expect(child1.find(wme)).to eq(wme)
      expect(child2.find(wme)).to eq(wme)
    end
  end

  it 'is disposable' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
    }

    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
    }
    expect(production).to have(0).tokens
  end

  it 'works with retractions' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
    }

    engine << [1, 2, 3]
    expect(production).to have(1).token

    engine.with_overlay do |overlay|
      overlay.retract [1, 2, 3]
      expect(production).to have(0).token
    end

    expect(production).to have(1).token
  end

  it 'generates into correct overlays' do
    production = engine << rule {
      forall {
        has 1, 2, :X
      }
      make {
        gen :X, 4, 5
      }
    }
    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
      expect(engine.find(3, 4, 5)).not_to be_nil
    }
    expect(production).to have(0).tokens
    expect(engine.find(3, 4, 5)).to be_nil
  end

  it 'works with neg rules' do
    prod = engine << rule {
      forall {
        neg :x, :y, :z
      }
    }

    expect(prod).to have(1).tokens

    engine.with_overlay do |overlay|
      overlay << %i[x y z]
      expect(prod).to have(0).tokens
    end

    expect(prod).to have(1).tokens
  end

  it 'works with assignments' do
    production = engine << rule {
      forall {
        has 1, 2, :X
        assign(:Something) { 6 }
      }
      make {
        collect :Something, :stuff
        gen :person, 'stuff', :Something
      }
    }

    engine.with_overlay { |overlay|
      overlay << [1, 2, 3]
      expect(production).to have(1).token
      expect(engine.find(:person, 'stuff', 6)).not_to be_nil
    }

    expect(production).to have(0).tokens
    expect(engine.find(:_, :_, :_)).to be_nil
  end
end
