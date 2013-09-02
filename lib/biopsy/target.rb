module Biopsy

  class TargetLoadError < Exception
  end

  class Target
    require 'yaml'
    require 'ostruct'

    # array of input files expected by the target constructor
    attr_accessor :input_files
    # array of output files to keep for submission to objective
    # functions during optimisation
    attr_accessor :output_files
    # hash mapping parameters to the ranges of values they can take
    attr_reader :parameter_ranges
    # path to the constructor code
    attr_reader :constructor_path
    attr_reader :domain

    # create a new Target instance.
    # arguments:
    # +:domain+ the domain to which this target belongs (see Domain documentation)
    def initialize domain
      @domain = domain
    end

    # load target with +name+.
    def load_by_name name
      path = self.locate_definition name
      raise TargetLoadError.new("Target definition file does not exist for #{name}") if path.nil?
      config = YAML::load_file(path)
      raise TargetLoadError.new("Target definition file #{path} is not valid YAML") if config.nil?
      missing = self.check_config config.deep_symbolize
      if missing
        msg = "Target definition file #{path} is missing required fields: #{missing}"
        raise TargetLoadError.new(msg)
      end
      errors = self.validate_config config
      unless errors.empty?
        raise TargetLoadError.new("Target definition file #{path} contains the following errors:\n - #{errors.join("\n - ")}")
      end
      self.store_config config
      self.check_constructor
    end

    # given the name of a target, return the path
    # to the definition YAML file. All +:target_dir+s defined in Settings are
    # searched and the first matching YAML file is loaded. 
    def locate_definition name
      Settings.instance.locate_config(:target_dir, name)
    end

    # verify that +:config+ contains values for all essential target settings
    # returning false if no keys are missing, or an array of the missing keys
    # if any cannot be found
    def check_config config
      required = %w(input_files output_files parameter_ranges constructor_path)
      missing = false
      required.each do |key|
        unless config.has_key? key.to_sym
          missing ||= []
          missing << key
        end
      end
      missing
    end

    # validate the config against the domain definition. Return an array
    # whose length will be the number of errors found. Thus an array of
    # length 0 indicates that the config is valid according to the domain
    # specification.
    def validate_config config
      @domain.target_valid? config
    end

    # Store the values in +:config+
    def store_config config
      config.each_pair do |key, value|
        self.instance_variable_set('@' + key.to_s, value)
      end
    end

    # Validate the constructor. True if valid, false otherwise.
    def check_constructor
      raise "constructor path is not defined for this target" if @constructor_path.nil?
      self.valid_ruby? @constructor_path
    end

    # true if file is valid ruby
    def valid_ruby? file
      return false unless ::File.exists? file
      result = `ruby -c #{file} &> /dev/null`
      !result.size.zero?
    end

  end # end of class Domain

end # end of module Biopsy