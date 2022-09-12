require 'spec_helper'

describe Wongi::Engine::Ruleset do

  before :each do
    Wongi::Engine::Ruleset.reset
  end

  context 'initially' do

    it 'should have no rules' do
      expect(Wongi::Engine::Ruleset.rulesets).to be_empty
    end

  end

  context 'when creating' do

    it 'should not register itself when not given a name' do
      ruleset = Wongi::Engine::Ruleset.new
      expect(ruleset.name).to be_nil
      expect(Wongi::Engine::Ruleset.rulesets).to be_empty
    end

    it 'should have a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      expect(ruleset.name).to be == 'testing-ruleset'
    end

    it 'should register itself when given a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      expect(Wongi::Engine::Ruleset.rulesets).not_to be_empty
      expect(Wongi::Engine::Ruleset[ruleset.name]).to be == ruleset
    end

  end

  it 'should be able to clear registered rulesets' do
    ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
    Wongi::Engine::Ruleset.reset
    expect(Wongi::Engine::Ruleset.rulesets).to be_empty
  end

  it 'should install creating rules into a rete' do
    rete = double 'rete'

    ruleset = Wongi::Engine::Ruleset.new
    rule = ruleset.rule('test-rule') { }

    expect(rete).to receive(:<<).with(rule).once
    ruleset.install rete
  end

end
