require 'helper'

class TestObjectiveHandler < Test::Unit::TestCase

  context "ObjectiveHandler" do

    setup do
      @h = Helper.new
      @h.setup_tmp_dir

      # and a target
      @h.setup_target
      target_name = @h.create_valid_target
      @target = Biopsy::Target.new
      @target.load_by_name target_name
      
      # and an objective
      @h.setup_objective
      @h.create_valid_objective
    end

    teardown do
      @h.cleanup
    end

    should "return loaded objectives on init" do
      oh = Biopsy::ObjectiveHandler.new @target
      refute oh.objectives.empty?
    end

    should "prefer local objective list to full set" do
      Dir.chdir(@h.objective_dir) do
        objective = %{
          class AnotherObjective < Biopsy::ObjectiveFunction
            def run(input, threads)
              10
            end
          end
        }
        File.open('another_objective.rb', 'w') do |f|
          f.puts objective
        end
        File.open('objectives.txt', 'w') do |f|
          f.puts 'another_objective'
        end
      end
      oh = Biopsy::ObjectiveHandler.new @target
      assert_equal 1, oh.objectives.length
      assert_equal 'AnotherObjective', oh.objectives.keys.first
    end

    should "run an objective and return the result" do
      oh = Biopsy::ObjectiveHandler.new @target
      values = {
        :a => 4,
        :b => 4,
        :c => 4
      }
      file = File.expand_path(File.join(@h.tmp_dir, 'output.txt'))
      File.open(file, 'w') do |f|
        f.puts values.to_yaml
      end
      Dir.chdir(@h.tmp_dir) do
        result = oh.run_for_output(nil, {:onlyfile => file})
        assert_equal 0, result
      end
    end

    should "perform euclidean distance dimension reduction" do
      oh = Biopsy::ObjectiveHandler.new @target
      results = {
        :a => {
          :optimum => 100,
          :weighting => 1,
          :result => 49,
          :max => 100
        },
        :b => {
          :optimum => 1,
          :weighting => 1,
          :result => 62,
          :max => 100
        },
        :c => {
          :optimum => 0,
          :weighting => 1,
          :result => 33,
          :max => 66
        }
      }
      assert_equal 0.47140452079103173, oh.dimension_reduce(results)
    end

  end # Experiment context

end # TestExperiment