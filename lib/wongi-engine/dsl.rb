module Wongi::Engine
  module DSL
    extend self

    def ruleset name = nil, &definition
      rs = Ruleset.new
      if ! name.nil?
        rs.name name
      end
      rs.instance_eval &definition if block_given?
      rs
    end

    def rule name = nil, &definition
      r = Rule.new name
      r.instance_eval &definition
      r
    end

    def query name, &definition
      q = Query.new name
      q.instance_eval &definition
      q
    end

    def dsl &definition
      Builder.new.build &definition
    end
  end

end

require 'wongi-engine/dsl/generated'
require 'wongi-engine/dsl/builder'
require 'wongi-engine/dsl/clause/generic'
require 'wongi-engine/dsl/clause/fact'
require 'wongi-engine/dsl/clause/assign'
require 'wongi-engine/dsl/clause/gen'
require 'wongi-engine/dsl/action/base'
require 'wongi-engine/dsl/rule'
require 'wongi-engine/dsl/ncc_subrule'
require 'wongi-engine/dsl/any_rule'
require 'wongi-engine/dsl/query'
require 'wongi-engine/dsl/assuming'
require 'wongi-engine/dsl/action/simple_action'
require 'wongi-engine/dsl/action/statement_generator'
require 'wongi-engine/dsl/action/simple_collector'
require 'wongi-engine/dsl/action/trace_action'
require 'wongi-engine/dsl/action/error_generator'

module Wongi::Engine::DSL
  dsl {
    section :forall

    clause :has, :fact
    accept Clause::Has

    clause :missing, :neg
    accept Clause::Neg

    clause :none, :ncc
    accept NccSubrule

    clause :any
    accept AnyRule

    clause :maybe, :optional
    accept Clause::Opt

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
    accept Clause::Assign

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
    accept Clause::Gen

    clause :trace
    action Action::TraceAction

    clause :error
    action Action::ErrorGenerator

    clause :collect
    action Action::SimpleCollector

    clause :action
    action Action::SimpleAction
  }
end
