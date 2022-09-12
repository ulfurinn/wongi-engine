require 'spec_helper'

describe Wongi::Engine::WME do
  # def capitalizing_rete
  #   rete = double 'rete'
  #   expect( rete ).to receive(:import).with("b").and_return("B")
  #   expect( rete ).to receive(:import).with("a").and_return("A")
  #   expect( rete ).to receive(:import).with("c").and_return("C")
  #   rete
  # end

  subject {
    Wongi::Engine::WME.new "a", "b", "c"
  }

  context 'a new WME' do
    it 'should initialize and expose members' do
      expect(subject.subject).to be == "a"
      expect(subject.predicate).to be == "b"
      expect(subject.object).to be == "c"
    end

    # it 'should use the rete to import members' do

    #   rete = capitalizing_rete

    #   wme = Wongi::Engine::WME.new "a", "b", "c", rete

    #   expect( wme.subject ).to be == "A"
    #   expect( wme.predicate ).to be == "B"
    #   expect( wme.object ).to be == "C"

    # end

  it {
    should be_manual
  }

  it {
    should_not be_generated
  }
  end

  # it 'should be able to import into rete' do

  #   rete = capitalizing_rete

  #   imported = subject.import_into rete

  #   expect( imported.subject ).to be == "A"
  #   expect( imported.predicate ).to be == "B"
  #   expect( imported.object ).to be == "C"

  # end

  it 'should compare instances' do
    wme1 = Wongi::Engine::WME.new "a", "b", "c"
    wme2 = Wongi::Engine::WME.new "a", "b", "c"
    wme3 = Wongi::Engine::WME.new "a", "b", "d"

    expect(wme1).to be == wme2
    expect(wme1).not_to be == wme3
  end

  it 'should not match against non-templates' do
    expect { subject =~ [1, 2, 3] }.to raise_error(Wongi::Engine::Error)
  end

  it 'should match against templates' do
    t1 = Wongi::Engine::Template.new "a", :_, :_
    t2 = Wongi::Engine::Template.new "b", :_, :_

    expect(subject).to be =~ t1
    expect(subject).not_to be =~ t2
  end
end
