require 'wongi-engine/dsl/dsl_extensions'
require 'wongi-engine/dsl/dsl_builder'
require 'wongi-engine/dsl/action'
require 'wongi-engine/dsl/generation_clause'
require 'wongi-engine/dsl/extension_clause'
require 'wongi-engine/dsl/generic_production_rule'
require 'wongi-engine/dsl/production_rule'
require 'wongi-engine/dsl/ncc_production_rule'
require 'wongi-engine/dsl/any_rule'
require 'wongi-engine/dsl/query'
require 'wongi-engine/dsl/assuming'
require 'wongi-engine/dsl/actions/simple_action'
require 'wongi-engine/dsl/actions/statement_generator'
require 'wongi-engine/dsl/actions/simple_collector'
require 'wongi-engine/dsl/actions/trace_action'
require 'wongi-engine/dsl/actions/error_generator'

module Wongi::Engine

  module DSL

    extend self

    def ruleset name = nil, &definition
      rs = Wongi::Engine::Ruleset.new
      if ! name.nil?
        rs.name name
      end
      rs.instance_eval &definition if block_given?
      rs
    end

    def rule name = nil, &definition
      r = Wongi::Engine::ProductionRule.new name
      r.instance_eval &definition
      r
    end

    def query name, &definition
      q = Wongi::Engine::Query.new name
      q.instance_eval &definition
      q
    end

    def dsl &definition
      Wongi::Engine::DSLBuilder.new.build &definition
    end

    dsl {

      section :forall

      clause :has, :fact
      accept Wongi::Engine::Template

      clause :missing, :neg
      accept Wongi::Engine::NegTemplate

      clause :none, :ncc
      accept Wongi::Engine::NccProductionRule

      clause :any
      accept Wongi::Engine::AnyRule

      clause :maybe, :optional
      accept Wongi::Engine::OptionalTemplate

      clause :same, :eq, :equal
      accept Wongi::Engine::EqualityTest

      clause :diff, :ne
      accept Wongi::Engine::InequalityTest

      clause :less
      accept Wongi::Engine::LessThanTest

      clause :greater
      accept Wongi::Engine::GreaterThanTest

      clause :assert, :dynamic
      accept Wongi::Engine::AssertingTest

      clause :assign, :introduce
      accept Wongi::Engine::Assignment

      clause :asserted, :added
      body { |s, p, o|
        has s, p, o, time: 0
        missing s, p, o, time: -1
      }

      clause :retracted, :removed
      body { |s, p, o|
        has s, p, o, time: -1
        missing s, p, o, time: 0
      }

      clause :kept, :still_has
      body { |s, p, o|
        has s, p, o, time: -1
        has s, p, o, time: 0
      }

      clause :kept_missing, :still_missing
      body { |s, p, o|
        missing s, p, o, time: -1
        missing s, p, o, time: 0
      }

      clause :assuming
      accept Wongi::Engine::AssumingClause

      section :make

      clause :gen
      accept Wongi::Engine::GenerationClause

      clause :trace
      action Wongi::Engine::TraceAction

      clause :error
      action Wongi::Engine::ErrorGenerator

      clause :collect
      action Wongi::Engine::SimpleCollector

      clause :action
      action Wongi::Engine::SimpleAction

    }
  end

end
