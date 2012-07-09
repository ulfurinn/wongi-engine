require 'spec_helper'

dsl {

  section :make
  clause :test_collector
  action Wongi::Engine::SimpleCollector.collector

}

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
        
      }
    }
  end

  def collection_rule
    rule('collector') {
      forall {
        has :X, nil, 42
      }
      make {
        test_collector :X
      }
    }
  end

  def generic_collection_rule
    rule('generic-collector') {
      forall {
        has :X, nil, 42
      }
      make {
        collect :X, :things_that_are_42
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
      generated = rete.facts.find( &:generated? )
      generated.should == Wongi::Engine::WME.new( "Bob", "friend", "Alice" )
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

  it 'should use collectors' do

    rete = Wongi::Engine::Dataset.new
    rete << collection_rule

    rete << [ "answer", "is", 42 ]
    rete << [ "question", "is", -1 ]

    collection = rete.collection(:test_collector)
    collection.should have(1).item
    collection.first.should == "answer"

  end

  it 'should use generic collectors' do

    rete = Wongi::Engine::Dataset.new
    rete << generic_collection_rule

    rete << [ "answer", "is", 42 ]
    rete << [ "question", "is", -1 ]

    collection = rete.collection(:things_that_are_42)
    collection.should have(1).item
    collection.first.should == "answer"

  end

  it 'should accept several rules' do

    lambda {
      rete = Wongi::Engine::Dataset.new
      rete << generic_collection_rule
      rete << collection_rule
    }.should_not raise_error

  end

  it 'should support prepared queries' do

    ds = Wongi::Engine::Dataset.new

    ds << query("test-query") {
      search_on :X
      forall {
        has :X, "is", :Y
      }
    }

    ds << ["answer", "is", 42]

    ds.execute "test-query", {X: "answer"}
    ds.results["test-query"].should have(1).tokens
    ds.results["test-query"].tokens.first[:Y].should == 42

  end

end
