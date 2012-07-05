require 'spec_helper'

describe 'the engine' do

  def reflexive_rule
    rule('reflexive') {
      forall {
        has :P, "reflexive", true
        has :A, :P, :B
      }
      make {
        trace :verbose, :values
        gen :B, :P, :A
      }
    }
  end

  context 'with a simple generative positive rule' do
  
    it 'should generate wmes with an existing rule' do
      rete = Wongi::Engine::Dataset.new

      rete << reflexive_rule

      rete << Wongi::Engine::WME.new( "friend", "reflexive", true )
      rete << Wongi::Engine::WME.new( "Alice", "friend", "Bob" )

      rete.should have(3).facts
      rete.facts.select( &:manual? ).should have(2).items
    end

    it 'should generate wmes with an added rule' do
      rete = Wongi::Engine::Dataset.new

      rete << Wongi::Engine::WME.new( "friend", "reflexive", true )
      rete << Wongi::Engine::WME.new( "Alice", "friend", "Bob" )

      rete.should have(2).facts

      rete << reflexive_rule

      rete.should have(3).facts
      rete.facts.select( &:manual? ).should have(2).items
    end

  end

end
