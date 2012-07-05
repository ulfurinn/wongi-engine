require 'spec_helper'

describe Wongi::Engine::Ruleset do

  before :each do
    Wongi::Engine::Ruleset.reset
  end

  context 'initially' do

    it 'should have no rules' do
      Wongi::Engine::Ruleset.rulesets.should be_empty
    end

  end

  context 'when creating' do

    it 'should not register itself when not given a name' do
      ruleset = Wongi::Engine::Ruleset.new
      ruleset.name.should be_nil
      Wongi::Engine::Ruleset.rulesets.should be_empty
    end

    it 'should have a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      ruleset.name.should == 'testing-ruleset'
    end

    it 'should register itself when given a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      Wongi::Engine::Ruleset.rulesets.should_not be_empty
      Wongi::Engine::Ruleset[ruleset.name].should == ruleset
    end

  end

  it 'should be able to clear registered rulesets' do
    ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
    Wongi::Engine::Ruleset.reset
    Wongi::Engine::Ruleset.rulesets.should be_empty
  end

  it 'should install creating rules into a rete' do
    rete = mock 'rete'
    
    ruleset = Wongi::Engine::Ruleset.new
    rule = ruleset.rule( 'test-rule' ) { }

    rete.should_receive(:<<).with(rule).once
    ruleset.install rete
  end

end
