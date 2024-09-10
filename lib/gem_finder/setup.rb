# frozen_string_literal: true

require "yaml"
require "gem_finder/setup/validate"

module GemFinder
  module Setup
    module_function

    def validate_yml!
      errors = config_yml["gems"].map do |name, metadata|
        validator = Validate.new(name: name, **metadata)
        validations << validator

        validator.error_status
      end.compact
      return true if errors.empty?

      log_level = config_yml.dig("invalid_config", "log_level") || "error"
      behavior = config_yml.dig("invalid_config", "behavior") || "exit"
    end

    def validations
      @validations ||= []
    end

    def run_validations!(behavior: nil)
      validations.each { _1.run_validation!(behavior: behavior) }
    end

    def config_yml
      @read_config_yml ||= begin
        path = GemFinder.configuration.yml_config_path
        file = File.read(path)
        erb = ERB.new(file)

        YAML.load(erb.result)
      end
    end
  end
end
