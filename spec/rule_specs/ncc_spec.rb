require 'spec_helper'

describe Wongi::Engine::NccNode do

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  def ncc_rule
    rule('ncc') {
      forall {
        has "base", "is", :Base
        none {
          has :Base, 2, :X
          has :X, 4, 5
        }
      }
    }
  end

  def ncc_rule_post_has
    rule('ncc post has') {
      forall {
        has "base", "is", :Base
        none {
          has :Base, 2, :X
          has :X, 4, 5
        }
        has "base", "is", :Base2
      }
    }
  end

  it 'should pass with a mismatching subchain' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]

    expect(production).to have(1).token

    engine << [1, 2, 3]

    expect(production).to have(1).token

    engine << [3, 4, 5]

    expect(production).to have(0).token

  end

  it 'should remain consistent after retraction' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]
    engine << [1, 2, 3]
    engine << [3, 4, 5]

    expect(production).to have(0).tokens

    engine.retract [3, 4, 5]
    expect( production ).to have(1).token

    engine.retract ["base", "is", 1]
    expect(production).to have(0).tokens

  end

  it 'can handle an alpha node template introduced after the negative-conjunctive-condition' do

    engine << ncc_rule_post_has

    production = engine.productions['ncc post has']

    engine << ["base", "is", 1]
    engine << [1, 2, 3]
    engine << [3, 4, 5]

    expect( production ).to have(0).tokens

    engine.retract [3, 4, 5]
    expect( production ).to have(1).tokens

    engine.retract ["base", "is", 1]
    expect( production ).to have(0).tokens

  end

  it 'should clean up correctly' do

    engine.rule :rule1 do
      forall {
        has :light_kitchen, :value, :on
      }
      make {
        #trace values: true, generation: true
        gen rule.name, :light_bathroom, :on
        gen rule.name, :want_action_for, :light_bathroom
      }
    end

    prod = engine.rule "action" do
      forall {
        has :Requestor, :want_action_for, :Actor
        has :Requestor, :Actor, :Value
        has :Requestor, :priority, :Priority
        ncc {
          has :OtherRequestor, :want_action_for, :Actor
          diff :OtherRequestor, :Requestor
          has :OtherRequestor, :priority, :OtherPriority
          greater :OtherPriority, :Priority
        }
      }
      make {
        #trace values: true, generation: true
        gen :Actor, :value, :Value
        gen :Actor, :last_user, :Requestor
      }
    end

    engine << [:user, :priority, 1]
    engine << [:rule1, :priority, 2]
    engine << [:poweruser, :priority, 3]
    engine << [:god, :priority, 4]

    engine << [:user, :want_action_for, :light_bathroom]
    engine << [:user, :light_bathroom, :off]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :off) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :user) ]

    engine << [:light_kitchen, :value, :on]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :on) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :rule1) ]

    engine << [:poweruser, :want_action_for, :light_bathroom]
    engine << [:poweruser, :light_bathroom, :super_on]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :super_on) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :poweruser) ]

    engine << [:god, :want_action_for, :light_bathroom]
    engine << [:god, :light_bathroom, :let_there_be_light]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :let_there_be_light) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :god) ]

  end

  it 'should clean up correctly with a different activation order' do

    engine.rule :rule1 do
      forall {
        has :light_kitchen, :value, :on
      }
      make {
        #trace values: true, generation: true
        gen rule.name, :light_bathroom, :on
        gen rule.name, :want_action_for, :light_bathroom
      }
    end

    prod = engine.rule "action" do
      forall {
        has :Requestor, :want_action_for, :Actor
        has :Requestor, :Actor, :Value
        has :Requestor, :priority, :Priority
        ncc {
          has :OtherRequestor, :want_action_for, :Actor
          diff :OtherRequestor, :Requestor
          has :OtherRequestor, :priority, :OtherPriority
          greater :OtherPriority, :Priority
        }
      }
      make {
        #trace values: true, generation: true
        gen :Actor, :value, :Value
        gen :Actor, :last_user, :Requestor
      }
    end

    engine << [:user, :priority, 2]
    engine << [:rule1, :priority, 1]
    engine << [:poweruser, :priority, 3]
    engine << [:god, :priority, 4]

    engine << [:user, :want_action_for, :light_bathroom]
    engine << [:user, :light_bathroom, :off]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :off) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :user) ]

    engine << [:light_kitchen, :value, :on]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :off) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :user) ]

    engine << [:poweruser, :want_action_for, :light_bathroom]
    engine << [:poweruser, :light_bathroom, :super_on]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :super_on) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :poweruser) ]

    engine << [:god, :want_action_for, :light_bathroom]
    engine << [:god, :light_bathroom, :let_there_be_light]
    expect( engine.select(:light_bathroom, :value, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :value, :let_there_be_light) ]
    expect( engine.select(:light_bathroom, :last_user, :_) ).to be == [ Wongi::Engine::WME.new(:light_bathroom, :last_user, :god) ]

  end

  it 'should ncc-deactivate without destroying tokens' do
    engine << rule {
      forall {
        has :Student, :is_a, :student
        has :Course, :is_a, :course
        none {
          has :Requirement, :is_a, :requirement
          has :Course, :Requirement, :RequiredGrade
          any {
            option {
              neg :Student, :Requirement, :_
            }
            option {
              has :Student, :Requirement, :ReceivedGrade
              less :ReceivedGrade, :RequiredGrade
            }
          }
        }
      }
      make {
        gen :Student, :passes_for, :Course
      }
    }

    %w( math science english bio ).each { |req| engine << [ req, :is_a, :requirement ] }
    %w( CourseA CourseB CourseC ).each  { |course| engine << [ course, :is_a, :course ] }
    engine << [ "StudentA", :is_a, :student ]

    engine << ["CourseA", "math", 50]
    engine << ["CourseA", "science", 50]

    engine << ["CourseB", "math", 50]
    engine << ["CourseB", "english", 50]

    engine << ["CourseC", "math", 50]
    engine << ["CourseC", "bio", 50]

    engine << ["StudentA", "math", 60]
    engine << ["StudentA", "science", 60]
    engine << ["StudentA", "bio", 40]

    expect(engine.find "StudentA", :passes_for, "CourseA").not_to be_nil
    expect(engine.find "StudentA", :passes_for, "CourseB").to be_nil
    expect(engine.find "StudentA", :passes_for, "CourseC").to be_nil
  end

  specify 'regression #71' do
    prod = engine << rule {
      forall {
        none {
          has "TestSet", :contains, :B
          has "MatchSet", :contains, :B
        }
      }
    }
    engine << ["TestSet", :contains, "not matching"]
    engine << ["MatchSet", :contains, "match 1"]
    engine << ["MatchSet", :contains, "match 2"]

    expect(prod).to have(1).tokens
  end

end
