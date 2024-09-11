# frozen_string_literal: true

require "yaml"

require "gem_enforcer/setup/helper/retrieval"
require "gem_enforcer/setup/helper/on_failure"
require "gem_enforcer/setup/helper/version"

module GemEnforcer
  module Setup
    class Validate
      attr_reader :gem_name, :params, :validation_status

      include Helper::Retrieval
      include Helper::OnFailure
      include Helper::Version

      def initialize(name:, **params)
        @params = params
        @gem_name = name

        @validation_status = validate!
      end

      # Allow behavior to be overridden if desired
      def run_validation!(behavior: nil)
        unless validation_status
          raise Error, "Unable to run validation with invalid config."
        end

        return true if current_version.nil?

        return true if version_execute?(version_list: retrieve_version_list)

        execute_on_failure!(behavior: behavior)
        false
      end

      def current_version
        Gem.loaded_specs[gem_name]&.version
      end

      def error_status
        return nil if errors.empty?

        errors.map { "#{gem_name}.#{_1}" }
      end

      private

      def errors
        @errors ||= []
      end

      def validate!
        boolean = validate_retrieval
        boolean &= validate_on_failure
        boolean &= validate_version

        boolean
      end
    end
  end
end
