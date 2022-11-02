require 'spec_helper'

describe Wongi::Engine::WME do
  # def capitalizing_rete
  #   rete = double 'rete'
  #   expect( rete ).to receive(:import).with("b").and_return("B")
  #   expect( rete ).to receive(:import).with("a").and_return("A")
  #   expect( rete ).to receive(:import).with("c").and_return("C")
  #   rete
  # end

  let(:wme) {
    described_class.new "a", "b", "c"
  }

  context 'a new WME' do
    it 'initializes and expose members' do
      expect(wme.subject).to be == "a"
      expect(wme.predicate).to be == "b"
      expect(wme.object).to be == "c"
    end
  end

  it 'compares instances' do
    wme1 = described_class.new "a", "b", "c"
    wme2 = described_class.new "a", "b", "c"
    wme3 = described_class.new "a", "b", "d"

    expect(wme1).to be == wme2
    expect(wme1).not_to be == wme3
  end

  it 'does not match against non-templates' do
    expect { wme =~ [1, 2, 3] }.to raise_error(Wongi::Engine::Error)
  end

  it 'matches against templates' do
    t1 = Wongi::Engine::Template.new "a", :_, :_
    t2 = Wongi::Engine::Template.new "b", :_, :_

    expect(wme).to be =~ t1
    expect(wme).not_to be =~ t2
  end
end
