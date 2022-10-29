require 'spec_helper'

describe Wongi::Engine::Ruleset do
  before do
    Wongi::Engine::Ruleset.reset
  end

  context 'initially' do
    it 'has no rules' do
      expect(Wongi::Engine::Ruleset.rulesets).to be_empty
    end
  end

  context 'when creating' do
    it 'does not register itself when not given a name' do
      ruleset = Wongi::Engine::Ruleset.new
      expect(ruleset.name).to be_nil
      expect(Wongi::Engine::Ruleset.rulesets).to be_empty
    end

    it 'has a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      expect(ruleset.name).to be == 'testing-ruleset'
    end

    it 'registers itself when given a name' do
      ruleset = Wongi::Engine::Ruleset.new 'testing-ruleset'
      expect(Wongi::Engine::Ruleset.rulesets).not_to be_empty
      expect(Wongi::Engine::Ruleset[ruleset.name]).to be == ruleset
    end
  end

  it 'is able to clear registered rulesets' do
    _ = Wongi::Engine::Ruleset.new 'testing-ruleset'
    Wongi::Engine::Ruleset.reset
    expect(Wongi::Engine::Ruleset.rulesets).to be_empty
  end

  it 'installs creating rules into a rete' do
    rete = double 'rete'

    ruleset = Wongi::Engine::Ruleset.new
    rule = ruleset.rule('test-rule') {}

    expect(rete).to receive(:<<).with(rule).once
    ruleset.install rete
  end
end
