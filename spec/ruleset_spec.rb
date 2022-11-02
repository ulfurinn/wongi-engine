require 'spec_helper'

describe Wongi::Engine::Ruleset do
  before do
    described_class.reset
  end

  context 'initially' do
    it 'has no rules' do
      expect(described_class.rulesets).to be_empty
    end
  end

  context 'when creating' do
    it 'does not register itself when not given a name' do
      ruleset = described_class.new
      expect(ruleset.name).to be_nil
      expect(described_class.rulesets).to be_empty
    end

    it 'has a name' do
      ruleset = described_class.new 'testing-ruleset'
      expect(ruleset.name).to be == 'testing-ruleset'
    end

    it 'registers itself when given a name' do
      ruleset = described_class.new 'testing-ruleset'
      expect(described_class.rulesets).not_to be_empty
      expect(described_class[ruleset.name]).to be == ruleset
    end
  end

  it 'is able to clear registered rulesets' do
    _ = described_class.new 'testing-ruleset'
    described_class.reset
    expect(described_class.rulesets).to be_empty
  end

  it 'installs creating rules into a rete' do
    rete = double 'rete'

    ruleset = described_class.new
    rule = ruleset.rule('test-rule') {}

    expect(rete).to receive(:<<).with(rule).once
    ruleset.install rete
  end
end
