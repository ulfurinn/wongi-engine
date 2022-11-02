require 'spec_helper'

class << self
  extend Wongi::Engine::DSL

  dsl {
    section :make
    clause :test_collector
    action Wongi::Engine::DSL::Action::SimpleCollector.collector
  }
end

describe Wongi::Engine::Network do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  context 'with a simple generative positive rule' do
    it 'generates wmes with an existing rule' do
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

    it 'generates wmes with an added rule' do
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

    it 'does not get confused by recursive activations' do
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

  it 'checks equality' do
    node = engine << rule('equality') {
      forall {
        fact :A, "same", :B
        same :A, :B
      }
    }

    engine << [42, "same", 42]
    expect(node.size).to eq(1)
  end

  it 'compares things' do
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

  it 'uses collectors' do
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

  it "properlies show error messages" do
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

  it 'uses generic collectors' do
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

  it 'accepts several rules' do
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

  it 'processes negative nodes' do
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

    it 'runs' do
      engine << ["answer", "is", 42]
      engine.execute "test-query", { X: "answer" }
      expect(engine.results["test-query"].size).to eq(1)
      expect(engine.results["test-query"].tokens.first[:Y]).to eq(42)
    end

    it 'runs several times' do
      engine << ["answer", "is", 42]
      engine << %w[question is 6x9]
      engine.execute "test-query", { X: "answer" }
      engine.execute "test-query", { X: "question" }
      expect(engine.results["test-query"].tokens.to_a.last[:Y]).to eq('6x9')
      expect(engine.results["test-query"].size).to eq(1)
    end
  end
end
