require 'spec_helper'

dsl {

  section :make
  clause :test_collector
  action Wongi::Engine::SimpleCollector.collector

}

describe 'the engine' do

  def dataset
    Wongi::Engine::Dataset.new
  end

  def equality_rule

  end

  def collection_rule

  end

  def generic_collection_rule

  end

  def neg_rule

  end

  context 'with a simple generative positive rule' do

    it 'should generate wmes with an existing rule' do
      rete = dataset

      rete << rule('reflexive') {
        forall {
          has :P, "reflexive", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

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

      rete << rule('reflexive') {
        forall {
          has :P, "reflexive", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

      rete.should have(3).facts
      rete.facts.select( &:manual? ).should have(2).items
    end

  end

  it 'should check equality' do

    rete = dataset
    rete << rule('equality') {
      forall {
        fact :A, "same", :B
        same :A, :B
      }
      make {

      }
    }

    rete << [ 42, "same", 42 ]

  end

  it 'should use collectors' do

    rete = dataset
    rete << rule('collector') {
      forall {
        has :X, :_, 42
      }
      make {
        test_collector :X
      }
    }

    rete << [ "answer", "is", 42 ]
    rete << [ "question", "is", -1 ]

    collection = rete.collection(:test_collector)
    collection.should have(1).item
    collection.first.should == "answer"

  end

  it 'should use generic collectors' do

    rete = dataset
    rete << rule('generic-collector') {
      forall {
        has :X, :_, 42
      }
      make {
        collect :X, :things_that_are_42
      }
    }

    rete << [ "answer", "is", 42 ]
    rete << [ "question", "is", -1 ]

    collection = rete.collection(:things_that_are_42)
    collection.should have(1).item
    collection.first.should == "answer"

  end

  it 'should accept several rules' do

    lambda do

      rete = dataset

      rete << rule('generic-collector') {
        forall {
          has :X, :_, 42
        }
        make {
          collect :X, :things_that_are_42
        }
      }

      rete << rule('collector') {
        forall {
          has :X, :_, 42
        }
        make {
          test_collector :X
        }
      }

    end.should_not raise_error

  end

  it 'should process negative nodes' do

    ds = dataset
    production = (ds << rule('negative') {
      forall {
        neg :_, :_, 42
      }
      })

    production.should have(1).tokens

    ds << [ "answer", "is", 42 ]

    production.should have(0).tokens

  end

  it 'should support prepared queries' do

    ds = dataset

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

  it 'should support negative subnets' do

    ds = dataset
    production = (ds << rule('ncc') {
      forall {
        has "base", "is", :Base
        none {
          has :Base, 2, :X
          has :X, 4, 5
        }
      }
    })

    ds << ["base", "is", 1]

    production.should have(1).tokens

    ds << [1, 2, 3]

    production.should have(1).tokens

    ds << [3, 4, 5]

    production.should have(0).tokens

    ds << ["base", "is", 2]

    production.should have(1).tokens

  end

  it 'should support optional matches' do

    ds = dataset

    production = (ds << rule('optional') {
      forall {
        has "answer", "is", :Answer
        maybe :Answer, "is", :Kind
      }
    })

    ds << ["answer", "is", 42]
    ds << ["answer", "is", 43]
    ds << [42, "is", "canonical"]

    production.should have(2).tokens

    canon = production.tokens.select { |token| not token[:Kind].nil? }
    canon.should have(1).items
    canon.first[:Answer].should == 42
    canon.first[:Kind].should == "canonical"

    non_canon = production.tokens.select { |token| token[:Kind].nil? }
    non_canon.should have(1).items
    non_canon.first[:Answer].should == 43

  end

end
