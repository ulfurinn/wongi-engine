# frozen_string_literal: true

require 'spec_helper'

describe 'Less Than Or Equal test' do
  before do
    @engine = Wongi::Engine.create
  end

  attr_reader :engine

  attr_reader :production

  def test_rule(&block)
    @production = (engine << rule('test-rule', &block))
  end

  it 'should interact with optional node correctly' do
    # before the fix, filters would try to piggy-back on optional templates

    test_rule do
      forall do
        has :Number, :assign_check, :_
        lte :Number, 6
      end
    end

    engine << [5, :assign_check, nil]
    engine << [6, :assign_check, nil]
    engine << [7, :assign_check, nil] # should not pass
    expect(@production.size).to eq(2)
  end
end
