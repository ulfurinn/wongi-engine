require 'spec_helper'

class << self
  extend Wongi::Engine::DSL

  dsl {
    section :make
    clause :test_collector
    action Wongi::Engine::DSL::Action::SimpleCollector.collector
  }
end

describe 'the engine' do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  context 'with a simple generative positive rule' do
    it 'should generate wmes with an existing rule' do
      engine << rule('symmetric') {
        forall {
          has :P, "symmetric", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

      engine << Wongi::Engine::WME.new("friend", "symmetric", true)
      engine << Wongi::Engine::WME.new("Alice", "friend", "Bob")

      expect(engine.facts.to_a.length).to eq(3)
      expect(engine.facts.select { engine.current_overlay.manual?(_1) }.length).to eq(2)
      generated = engine.facts.select { engine.current_overlay.generated?(_1) }
      expect(generated).to eq([Wongi::Engine::WME.new("Bob", "friend", "Alice")])
    end

    it 'should generate wmes with an added rule' do
      engine << Wongi::Engine::WME.new("friend", "symmetric", true)
      engine << Wongi::Engine::WME.new("Alice", "friend", "Bob")

      expect(engine.facts.to_a.length).to eq(2)

      engine << rule('symmetric') {
        forall {
          has :P, "symmetric", true
          has :A, :P, :B
        }
        make {
          gen :B, :P, :A
        }
      }

      expect(engine.facts.to_a.size).to eq(3)
      expect(engine.facts.select { engine.current_overlay.manual?(_1) }.size).to eq(2)
    end

    it 'should not get confused by recursive activations' do
      engine << rule('reflexive') {
        forall {
          has :Predicate, "reflexive", true
          has :X, :Predicate, :Y
        }
        make {
          gen :X, :Predicate, :X
          gen :Y, :Predicate, :Y
        }
      }

      engine << [:p, "reflexive", true]
      engine << %i[x p y]

      expect(engine.wmes.count).to eq(4)
      expect(engine.select(:x, :p, :x).count).to eq(1)
      expect(engine.select(:y, :p, :y).count).to eq(1)
    end
  end

  it 'should check equality' do
    node = engine << rule('equality') {
      forall {
        fact :A, "same", :B
        same :A, :B
      }
    }

    engine << [42, "same", 42]
    expect(node.size).to eq(1)
  end

  it 'should compare things' do
    engine << rule('less') {
      forall {
        has :A, :age, :N1
        has :B, :age, :N2
        less :N1, :N2
      }
      make {
        gen :A, :younger, :B
      }
    }

    engine << rule('less') {
      forall {
        has :A, :age, :N1
        has :B, :age, :N2
        greater :N1, :N2
      }
      make {
        gen :A, :older, :B
      }
    }

    engine << ["Alice", :age, 42]
    engine << ["Bob", :age, 43]

    items = engine.select "Alice", :younger, "Bob"
    expect(items.size).to eq(1)

    items = engine.select "Bob", :older, "Alice"
    expect(items.size).to eq(1)
  end

  it 'should use collectors' do
    engine << rule('collector') {
      forall {
        has :X, :_, 42
      }
      make {
        test_collector :X
      }
    }

    engine << ["answer", "is", 42]
    engine << ["question", "is", -1]

    collection = engine.collection(:test_collector)
    expect(collection.size).to eq(1)
    expect(collection.first).to eq("answer")
  end

  it "should properly show error messages" do
    engine << rule("Error rule") {
      forall {
        has :_, :_, :TestNumber
        greater :TestNumber, 0
      }
      make {
        error "An error has occurred"
      }
    }

    engine << ["A", "B", 1]

    error_messages = engine.errors.map(&:message)
    expect(error_messages).to eq(["An error has occurred"])
  end

  it 'should use generic collectors' do
    engine << rule('generic-collector') {
      forall {
        has :X, :_, 42
      }
      make {
        collect :X, :things_that_are_42
      }
    }

    engine << ["answer", "is", 42]
    engine << ["question", "is", -1]

    collection = engine.collection(:things_that_are_42)
    expect(collection.size).to eq(1)
    expect(collection.first).to eq("answer")
  end

  it 'should accept several rules' do
    expect {
      engine << rule('generic-collector') {
        forall {
          has :X, :_, 42
        }
        make {
          collect :X, :things_that_are_42
        }
      }

      engine << rule('collector') {
        forall {
          has :X, :_, 42
        }
        make {
          test_collector :X
        }
      }
    }.not_to raise_error
  end

  it 'should process negative nodes' do
    production = (engine << rule('negative') {
                    forall {
                      neg :_, :_, 42
                    }
                  })

    expect(production.size).to eq(1)

    engine << ["answer", "is", 42]

    expect(production.size).to eq(0)
  end

  context 'queries' do
    before do
      engine << query("test-query") {
        search_on :X
        forall {
          has :X, "is", :Y
        }
      }
    end

    it 'should run' do
      engine << ["answer", "is", 42]
      engine.execute "test-query", { X: "answer" }
      expect(engine.results["test-query"].size).to eq(1)
      expect(engine.results["test-query"].tokens.first[:Y]).to eq(42)
    end

    it 'should run several times' do
      engine << ["answer", "is", 42]
      engine << %w[question is 6x9]
      engine.execute "test-query", { X: "answer" }
      engine.execute "test-query", { X: "question" }
      expect(engine.results["test-query"].tokens.to_a.last[:Y]).to eq('6x9')
      expect(engine.results["test-query"].size).to eq(1)
    end
  end

  xcontext 'with timelines' do
    it 'should not match with no past point' do
      production = engine.rule {
        forall {
          has 1, 2, 3, time: -1
        }
      }

      expect(production.size).to eq(0)

      engine << [1, 2, 3]

      expect(production.size).to eq(0)
    end

    it 'should match a simple past point' do
      production = engine.rule {
        forall {
          has 1, 2, 3, time: -1
        }
      }

      engine << [1, 2, 3]
      engine.snapshot!

      expect(production.size).to eq(1)
    end

    context 'using the :asserted clause' do
      it 'should match asserted items' do
        count = 0
        production = engine.rule do
          forall {
            asserted 1, 2, 3
          }
          make { action { count += 1 } }
        end
        expect(production.size).to eq(0)
        engine.snapshot!
        engine << [1, 2, 3]
        expect(production.size).to eq(1)
        # puts count
      end

      it 'should not match kept items' do
        count = 0
        production = engine.rule do
          forall {
            asserted 1, 2, 3
          }
          make { action { count += 1 } }
        end
        engine << [1, 2, 3]
        expect(production.size).to eq(1)
        engine.snapshot!
        expect(production.size).to eq(0)
        # puts count
      end
    end

    context 'using the :kept clause' do
      it 'should match kept items' do
        count = 0
        production = engine.rule do
          forall {
            kept 1, 2, 3
          }
          make { action { count += 1 } }
        end
        engine << [1, 2, 3]
        expect(production.size).to eq(0)
        engine.snapshot!
        expect(production.size).to eq(1)
        # puts count
      end

      it 'should not match asserted wmes' do
        count = 0
        production = engine.rule do
          forall {
            kept 1, 2, 3
          }
          make { action { count += 1 } }
        end
        expect(production.size).to eq(0)
        engine.snapshot!
        engine << [1, 2, 3]
        expect(production.size).to eq(0)
        # puts count
      end
    end
  end
end
