def ruleset name = nil, &definition
  rs = Wongi::Engine::Ruleset.new
  if ! name.nil?
    rs.name name
  end
  rs.instance_eval &definition if block_given?
  rs
end

def rule name, &definition
  r = Wongi::Engine::ProductionRule.new name
  r.instance_eval &definition
  r
end

def dsl &definition
  Wongi::Engine::DSLBuilder.new.build &definition
end

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
require 'wongi-engine/dsl/actions/statement_generator'
require 'wongi-engine/dsl/actions/simple_collector'
require 'wongi-engine/dsl/actions/trace_action'
require 'wongi-engine/dsl/actions/error_generator'



dsl {

  section :forall

  clause :has, :fact
  action Wongi::Engine::Template

  clause :missing, :neg
  action Wongi::Engine::NegTemplate

  clause :none
  action Wongi::Engine::NccProductionRule

  clause :any
  action Wongi::Engine::AnyRule

  clause :maybe
  accept Wongi::Engine::OptionalTemplate

  clause :same
  accept Wongi::Engine::EqualityTest

  clause :diff
  accept Wongi::Engine::InequalityTest

  clause :asserted
  body { |s, p, o|
    missing s, p, o, -1
    has s, p, o, 0
  }

  clause :retracted 
  body { |s, p, o|
    has s, p, o, -1
    missing s, p, o, 0
  }

  clause :kept, :still_has
  body { |s, p, o|
    has s, p, o, -1
    has s, p, o, 0
  }

  clause :kept_missing, :still_missing
  body { |s, p, o|
    missing s, p, o, -1
    missing s, p, o, 0
  }


  section :make

  clause :gen
  accept Wongi::Engine::GenerationClause

  clause :trace
  action Wongi::Engine::TraceAction

  clause :error
  action Wongi::Engine::ErrorGenerator

}

