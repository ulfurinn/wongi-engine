module Wongi::Engine
  module DSL
    module_function def sections
      @sections ||= {}
    end

    module_function def ruleset(name = nil, &definition)
      rs = Ruleset.new
      rs.name name if name
      rs.instance_eval(&definition) if block_given?
      rs
    end

    module_function def rule(name = nil, &definition)
      r = Rule.new name
      r.instance_eval(&definition)
      r
    end

    module_function def query(name, &definition)
      q = Query.new name
      q.instance_eval(&definition)
      q
    end

    module_function def dsl(&definition)
      Builder.new.build(&definition)
    end
  end
end

require 'wongi-engine/dsl/generated'
require 'wongi-engine/dsl/builder'
require 'wongi-engine/dsl/clause/generic'
require 'wongi-engine/dsl/clause/fact'
require 'wongi-engine/dsl/clause/aggregate'
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
require 'wongi-engine/dsl/action/assign_action'

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

    clause :lte
    accept Wongi::Engine::LessThanOrEqualTest

    clause :greater
    accept Wongi::Engine::GreaterThanTest

    clause :gte
    accept Wongi::Engine::GreaterThanOrEqualTest

    clause :aggregate
    accept Clause::Aggregate

    clause :least, :min
    body { |s, p, o, opts|
      aggregate s, p, o, on: opts[:on], function: :min, assign: opts[:assign]
    }

    clause :greatest, :max
    body { |s, p, o, opts|
      aggregate s, p, o, on: opts[:on], function: :max, assign: opts[:assign]
    }

    clause :count
    body { |s, p, o, opts|
      aggregate s, p, o, map: ->(_) { 1 }, function: -> { _1.inject(&:+) }, assign: opts[:assign]
    }

    clause :assert, :dynamic
    accept Wongi::Engine::AssertingTest

    clause :assign, :introduce, :let
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

    clause :assign
    action Action::AssignAction
  }
end
