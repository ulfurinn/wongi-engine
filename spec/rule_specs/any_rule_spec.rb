require 'spec_helper'

describe "ANY rule" do

  include Wongi::Engine::DSL

  before :each do
    @engine = Wongi::Engine.create
  end

  def engine
    @engine
  end

  context "with just one option" do

    it "should act like a positive matcher" do

      engine << rule('one-option') {
        forall {
          any {
            option {
              has 1, 2, :X
              has :X, 4, 5
            }
          }
        }
      }

      production = engine.productions['one-option']

      engine << [1, 2, 3]
      engine << [3, 4, 5]

      expect(production.size).to eq(1)

    end

  end

  context "with several options" do

    specify "all matching branches must pass" do

      engine << rule('two-options') {
        forall {
          has 1, 2, :X
          any {
            option {
              has :X, 4, 5
            }
            option {
              has :X, "four", "five"
            }
          }
        }
        make {
          collect :X, :threes
        }
      }

      production = engine.productions['two-options']

      engine << [1, 2, 3]
      engine << [3, 4, 5]
      engine << [1, 2, "three"]
      engine << ["three", "four", "five"]

      expect(production.size).to eq(2)
      expect( engine.collection(:threes) ).to include(3)
      expect( engine.collection(:threes) ).to include("three")

    end

  end

  context "with two options and same assignments" do
    let :production do
      engine << rule do
        forall {
          any {
            option {
              has :A, :path1, :PathVar
            }
            option {
              has :A, :path2, :PathVar
            }
          }
        }
        make {
          collect :PathVar, :paths
        }
      end
    end

    specify 'should fire on the first path', debug: true do
      engine << [:x, :path1, true]
      expect(production.tokens).to have(1).item
      expect(engine.collection(:paths)).to include(true)
    end

    specify 'should fire on the second path', debug: true do
      engine << [:x, :path2, true]
      expect(production.tokens).to have(1).item
      expect(engine.collection(:paths)).to include(true)
    end
  end

  describe "broken ANY interaction" do
    let :passed do
      rule('passed') do
        forall {
          any {
            option {
              has :Event, :exam_name, 'Final Exam'
            }
            option {
              has :Event, :exam_name, 'Retake Exam'
            }
          }
          has :Event, :grade, "pass"
        }
        make {
          collect :Event, :passed
        }
      end
    end

    let :fail_final do
      rule('fail final') do
        forall {
          has :Event, :exam_name, 'Final Exam'
          has :Event, :grade, "fail"
        }
        make {
          collect :Event, :failed_final
        }
      end
    end

    let :fail_retake do
      rule('fail retake') do
        forall {
          has :Event, :exam_name, 'Retake Exam'
          has :Event, :grade, "fail"
        }
        make {
          collect :Event, :failed_retake
        }
      end
    end

    before do
      # add the facts
      engine << [:fail_final_event, :exam_name, 'Final Exam']
      engine << [:fail_final_event, :grade, 'fail']

      engine << [:fail_retake_event, :exam_name, 'Retake Exam']
      engine << [:fail_retake_event, :grade, 'fail']
    end

    shared_examples 'shared expectations' do
      it 'has nothing passed' do
        expect(engine.collection(:passed)).to match_array([])
      end

      it 'has correct failed final' do
        expect(engine.collection(:failed_final)).to match_array([:fail_final_event])
      end

      it 'has correct failed retake' do
        expect(engine.collection(:failed_retake)).to match_array([:fail_retake_event])
      end
    end

    context "with option production absent (OK)" do
      before do
        #engine << passed
        engine << fail_final
        engine << fail_retake
      end

      it_behaves_like 'shared expectations'
    end

    context "with option production last (OK)" do
      before do
        engine << fail_final
        engine << fail_retake
        engine << passed
      end

      it_behaves_like 'shared expectations'
    end

    context "with option production first (BAD)" do
      before do
        engine << passed
        engine << fail_final
        engine << fail_retake
      end

      it_behaves_like 'shared expectations'
    end
  end
end
