require 'spec_helper'

describe Wongi::Engine::WME do

  def capitalizing_rete
    rete = mock 'rete'
    rete.should_receive(:import).with("a").and_return("A")
    rete.should_receive(:import).with("b").and_return("B")
    rete.should_receive(:import).with("c").and_return("C")
    rete
  end

  subject {
    Wongi::Engine::WME.new "a", "b", "c"
  }

  context 'a new WME' do

    it 'should initialize and expose members' do
      subject.subject.should == "a"
      subject.predicate.should == "b"
      subject.object.should == "c"
    end

    it 'should use the rete to import members' do

      rete = capitalizing_rete

      wme = Wongi::Engine::WME.new "a", "b", "c", rete

      wme.subject.should == "A"
      wme.predicate.should == "B"
      wme.object.should == "C"

    end


  specify {
    subject.should be_manual
  }

  specify {
    subject.should_not be_generated
  }

  end

  it 'should be able to import into rete' do

    rete = capitalizing_rete

    imported = subject.import_into rete

    imported.subject.should == "A"
    imported.predicate.should == "B"
    imported.object.should == "C"

  end

  it 'should compare instances' do

    wme1 = Wongi::Engine::WME.new "a", "b", "c"
    wme2 = Wongi::Engine::WME.new "a", "b", "c"
    wme3 = Wongi::Engine::WME.new "a", "b", "d"

    wme1.should == wme2
    wme1.should_not == wme3

  end

  it 'should not match against non-templates' do
    lambda { subject =~ [1, 2, 3] }.should raise_error
  end

  it 'should match against templates' do
    t1 = Wongi::Engine::Template.new "a", nil, nil
    t2 = Wongi::Engine::Template.new "b", nil, nil

    subject.should =~ t1
    subject.should_not =~ t2
  end

end
