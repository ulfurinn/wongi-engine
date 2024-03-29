# frozen_string_literal: true

require 'spec_helper'

describe Wongi::Engine::GreaterThanOrEqualTest do
  include Wongi::Engine::DSL
  let(:engine) { Wongi::Engine.create }

  it 'interacts with optional node correctly' do
    # before the fix, filters would try to piggy-back on optional templates

    production = engine << rule {
      forall {
        has :Number, :assign_check, :_
        gte :Number, 6
      }
    }

    engine << [6, :assign_check, nil]
    engine << [7, :assign_check, nil]
    engine << [5, :assign_check, nil]
    expect(production.size).to eq(2)
  end
end
