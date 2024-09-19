# frozen_string_literal: true


require "gem_enforcer/setup/helper/on_failure"
require "gem_enforcer/setup/helper/version_enforcer"

module GemEnforcer
  module Setup
    class Behavior
      attr_reader :gem_name, :params, :index

      def initialize(gem_name:, index:, **params)
        @gem_name = gem_name
        @index = index
        @params = params.transform_keys(&:to_sym)
      end

      def valid_config?
        @valid_config ||= validate_config
      end

      def run_behavior!(version_list:, version:)
        unless valid_config?
          raise ConfigError, "Attempted to run validations with invalid Version Configurations"
        end

        return true if version.nil?
        return true if version_enforcer.valid_gem_versions?(version_list:, version:)

        false
      end

      def error_status
        return nil if errors.empty?

        errors.map { "behaviors[#{index}].#{_1}" }
      end

      def version_enforcer
        @version_enforcer ||= Helper::VersionEnforcer.new(gem_name:, version_enforce: params[:version_enforce])
      end

      def on_failure
        @on_failure ||= Helper::OnFailure.new(gem_name:, on_failure: params[:on_failure])
      end

      def run_failure!(message:, version:, version_list:)
        params = {
          version:,
          c: version_list.max,
          versions_behind: version_enforcer.versions_behind(version_list:, version:),
        }
        on_failure.run_on_failure!(message:, **params)
      end

      private

      def errors
        @errors ||= []
      end

      def validate_config
        boolean = version_enforcer.valid_config?
        boolean &= on_failure.valid_config?

        @errors = Array(version_enforcer.errors).compact + Array(on_failure.errors).compact
        @errors.length == 0
      end
    end
  end
end
