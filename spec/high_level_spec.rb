require 'spec_helper'

describe 'the engine' do

  def reflexive_rule
    rule('reflexive') {
      forall {
        has :P, "reflexive", true
        has :A, :P, :B
      }
      make {
        gen :B, :P, :A
      }
    }
  end

  def equality_rule
    rule('equality') {
      forall {
        fact :A, "same", :B
        same :A, :B
      }
      make {
        trace values: true
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

  it 'should check equality' do

    rete = Wongi::Engine::Dataset.new
    rete << equality_rule

    rete << [ 42, "same", 42 ]

  end

end
