require 'spec_helper'

describe 'action classes' do
  include Wongi::Engine::DSL

  let :engine do
    Wongi::Engine.create
  end

  let :action_class do
    Class.new do
      class << self
        attr_accessor :execute_body, :deexecute_body
      end

      def execute(token)
        self.class.execute_body.call(token)
      end

      def deexecute(token)
        self.class.deexecute_body.call(token)
      end
    end
  end

  it 'has appropriate callbacks executed' do
    executed = 0
    deexecuted = 0

    klass = action_class

    klass.execute_body = lambda do |_token|
      executed += 1
    end
    klass.deexecute_body = lambda do |_token|
      deexecuted += 1
    end

    engine << rule {
      forall {
        has :A, :x, :B
      }
      make {
        action klass
      }
    }

    engine << [1, :x, 2]
    expect(executed).to be == 1
    expect(deexecuted).to be == 0

    engine.retract [1, :x, 2]
    expect(executed).to be == 1
    expect(deexecuted).to be == 1
  end
end
