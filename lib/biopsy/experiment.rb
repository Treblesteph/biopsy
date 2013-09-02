# Optimisation Framework: Experiment
#
# == Description
#
# The Experiment object encapsulates the data and methods that represent
# the optimisation experiment being carried out.
#
# The metadata necessary to conduct the experiment, as well as the
# settings for the experiment, are stored here.
#
# It is also the main process controller for the entire optimisation
# cycle. It takes user input, runs the target program, the objective function(s)
# and the optimisation algorithm, looping through the optimisation cycle until
# completion and then returning the output.
module Biopsy

  class Experiment

    attr_reader :inputs, :outputs, :retain_intermediates, :target, :start, :algorithm

    # Returns a new Experiment
    def initialize(target_name, domain_name, start=nil, algorithm=nil)
      @domain = Domain.new domain_name
      @start = start
      @algorithm = algorithm

      self.load_target target_name
      self.select_algorithm
      self.select_starting_point
    end

    # return the set of parameters to evaluate first
    def select_starting_point
      return unless @start.nil?
      if @algorithm && @algorithm.knows_starting_point?
        @start = @algorithm.select_starting_point
      else
        @start = self.random_start_point
      end
    end

    # Return a random set of parameters from the parameter space.
    def random_start_point
      Hash[@target.parameter_ranges.map { |p, r| [p, r.sample] }] 
    end

    # select the optimisation algorithm to use
    def select_algorithm
      @algorithm = ParameterSweeper.new(@target.parameter_ranges)
      return if @algorithm.combinations.size < Settings.instance.sweep_cutoff
      @algorithm = TabuSearch.new(@target.parameter_ranges)
    end

    # load the target named +:target_name+
    def load_target target_name
      @target = Target.new @domain
      @target.load_by_name target_name
    end

    # Runs the experiment until the completion criteria
    # are met. On completion, returns the best parameter
    # set.
    def run
      in_progress = true
      @current_params = select_first_params
      while in_progress do
        run_iteration
        # update the best result
        @best = @optimiser.best
        # have we finished?
        in_progress = !@optimiser.finished?
      end
      return @best
    end

    # Runs a single iteration of the optimisation,
    # encompassing the program, objective(s) and optimiser.
    # Returns the output of the optimiser.
    def run_iteration
      # run the target
      run_data = @constructor.run @current_params
      # evaluate with objectives
      result = @objective.run run_data
      # get next steps from optimiser
      @current_params = @optimiser.run result
    end

  end # end of class RunHandler

end # end of module Biopsy