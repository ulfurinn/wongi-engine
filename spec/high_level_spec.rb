require 'spec_helper'

dsl {

  section :make
  clause :test_collector
  action Wongi::Engine::SimpleCollector.collector

}

describe 'the engine' do

  before :each do
    @rete = Wongi::Engine::Network.new
  end

  def rete
    @rete
  end

  context 'with a simple generative positive rule' do

    it 'should generate wmes with an existing rule' do

      rete << rule('symmetric') {
        forall {
          has :P, "symmetric", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

      rete << Wongi::Engine::WME.new( "friend", "symmetric", true )
      rete << Wongi::Engine::WME.new( "Alice", "friend", "Bob" )
      
      expect(rete.facts.to_a.length).to eq(3)
      expect(rete.facts.select( &:manual? ).length).to eq(2)
      generated = rete.facts.find( &:generated? )
      generated.should == Wongi::Engine::WME.new( "Bob", "friend", "Alice" )
    end

    it 'should generate wmes with an added rule' do

      rete << Wongi::Engine::WME.new( "friend", "symmetric", true )
      rete << Wongi::Engine::WME.new( "Alice", "friend", "Bob" )

      expect(rete.facts.to_a.length).to eq(2)

      rete << rule('symmetric') {
        forall {
          has :P, "symmetric", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

      expect(rete.facts.to_a.length).to eq(3)
      expect(rete.facts.select( &:manual? ).size).to eq(2)
    end

    it 'should not get confused by recursive activations' do

      rete << rule('reflexive') {
        forall {
          has :Predicate, "reflexive", true
          has :X, :Predicate, :Y
        }
        make {
          gen :X, :Predicate, :X
          gen :Y, :Predicate, :Y
        }
      }

      rete << [:p, "reflexive", true]
      rete << [:x, :p, :y]

      expect(rete.wmes.to_a.length).to eq(4)
      expect(rete.select(:x, :p, :x).length).to eq(1)
      expect(rete.select(:y, :p, :y).length).to eq(1)

    end

  end

  it 'should check equality' do

    node = rete << rule('equality') {
      forall {
        fact :A, "same", :B
        same :A, :B
      }
      make {

      }
    }

    rete << [ 42, "same", 42 ]
    expect(node.size).to eq(1)

  end

  it 'should compare things' do

    rete << rule('less') {
      forall {
        has :A, :age, :N1
        has :B, :age, :N2
        less :N1, :N2
      }
      make {
        gen :A, :younger, :B
      }
    }

    rete << rule('less') {
      forall {
        has :A, :age, :N1
        has :B, :age, :N2
        greater :N1, :N2
      }
      make {
        gen :A, :older, :B
      }
    }

    rete << ["Alice", :age, 42]
    rete << ["Bob", :age, 43]

    items = rete.select "Alice", :younger, "Bob"
    expect(items.size).to eq(1)

    items = rete.select "Bob", :older, "Alice"
    expect(items.size).to eq(1)

  end

  it 'should use collectors' do

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
    expect(collection.size).to eq(1)
    expect(collection.first).to eq("answer")

  end

  it 'should use generic collectors' do

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
    expect(collection.size).to eq(1)
    expect(collection.first).to eq("answer")

  end

  it 'should accept several rules' do

    lambda do

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

    production = (rete << rule('negative') {
      forall {
        neg :_, :_, 42
      }
      })

    expect(production.size).to eq(1)

    rete << [ "answer", "is", 42 ]

    expect(production.size).to eq(0)

  end

  it 'should support prepared queries' do

    rete << query("test-query") {
      search_on :X
      forall {
        has :X, "is", :Y
      }
    }

    rete << ["answer", "is", 42]

    rete.execute "test-query", {X: "answer"}
    expect(rete.results["test-query"].size).to eq(1)
    expect(rete.results["test-query"].tokens.first[:Y]).to eq(42)

  end
  
  context 'with timelines' do

    it 'should not match with no past point' do

      production = rete.rule {
        forall {
          has 1, 2, 3, time: -1
        }
      }

      expect(production.size).to eq(0)

      rete << [1, 2, 3]

      expect(production.size).to eq(0)

    end

    it 'should match a simple past point' do

      production = rete.rule {
        forall {
          has 1, 2, 3, time: -1
        }
      }

      rete << [1, 2, 3]
      rete.snapshot!

      expect(production.size).to eq(1)

    end

    context 'using the :asserted clause' do

      it 'should match asserted items' do
        count = 0
        production = rete.rule do
          forall {
            asserted 1, 2, 3
          }
          make { action { count += 1} }
        end
        expect(production.size).to eq(0)
        rete.snapshot!
        rete << [1, 2, 3]
        expect(production.size).to eq(1)
        #puts count
      end

      it 'should not match kept items' do
        count = 0
        production = rete.rule do
          forall {
            asserted 1, 2, 3
          }
          make { action { count += 1} }
        end
        rete << [1, 2, 3]
        expect(production.size).to eq(1)
        rete.snapshot!
        expect(production.size).to eq(0)
        #puts count
      end

    end

    context 'using the :kept clause' do

      it 'should match kept items' do
        count = 0
        production = rete.rule do
          forall {
            kept 1, 2, 3
          }
          make { action { count += 1} }
        end
        rete << [1, 2, 3]
        expect(production.size).to eq(0)
        rete.snapshot!
        expect(production.size).to eq(1)
        #puts count
      end

      it 'should not match asserted wmes' do
        count = 0
        production = rete.rule do
          forall {
            kept 1, 2, 3
          }
          make { action { count += 1} }
        end
        expect(production.size).to eq(0)
        rete.snapshot!
        rete << [1, 2, 3]
        expect(production.size).to eq(0)
        #puts count
      end

    end

  end

end
