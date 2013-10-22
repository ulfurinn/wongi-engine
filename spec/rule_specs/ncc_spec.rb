require 'spec_helper'

describe "NCC rule" do

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

  it 'should pass with a mismatching subchain' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]

    production.should have(1).tokens

    engine << [1, 2, 3]

    production.should have(1).tokens

    engine << [3, 4, 5]

    production.should have(0).tokens

  end

  it 'should remain consistent after retraction' do

    engine << ncc_rule
    production = engine.productions['ncc']

    engine << ["base", "is", 1]
    engine << [1, 2, 3]
    engine << [3, 4, 5]

    production.should have(0).tokens

    engine.retract [3, 4, 5]
    production.should have(1).tokens

    engine.retract ["base", "is", 1]
    production.should have(0).tokens

  end

  it 'should clean up correctly' do

    engine.rule :rule1 do
      forall {
        has :light_kitchen, :value, :on
      }
      make {
        #trace values: true, generation: true
        gen self.name, :light_bathroom, :on
        gen self.name, :want_action_for, :light_bathroom
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
        gen self.name, :light_bathroom, :on
        gen self.name, :want_action_for, :light_bathroom
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

end
