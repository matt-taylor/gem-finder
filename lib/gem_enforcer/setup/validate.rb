# frozen_string_literal: true

require "gem_enforcer/setup/behavior"
require "gem_enforcer/setup/helper/retrieval"

module GemEnforcer
  module Setup
    class Validate
      attr_reader :gem_name, :params, :behaviors, :retrieval

      def initialize(name:, **params)
        @params = params
        @gem_name = name
        @behaviors = []
        @errors = []
      end

      def run_validation!
        unless valid_config?
          raise Error, "Unable to run validation with invalid config."
        end
        return true if current_version.nil?

        version_list = retrieval.retrieve_version_list
        passed_behavior, failed_behavior = behaviors.partition { _1.run_behavior!(version_list:, version: current_version) }

        return true if failed_behavior.empty?


        failed_behavior.each do |failed|
          default_message = failed.version_enforcer.error_validation_message
          failed.run_failure!(message: default_message, version: current_version, version_list: version_list)
        end

        false
      end

      def current_version
        Gem.loaded_specs[gem_name]&.version
      end

      def valid_config?
        @valid_config ||= validate_config
      end

      def error_status
        return nil if errors.empty?

        errors.map { "#{gem_name}.#{_1}" }
      end

      private

      def validate_config
        generate_behaviors!
        generate_retreival!

        boolean = true
        if behaviors.length == 0
          @errors << "behaviors: At least 1 behavior is expected per gem validation"
          boolean = false
        else
          unless behaviors.all? { _1.valid_config? }
            # at least 1 beavior failed validation
            behaviors.each do |b|
              @errors += b.error_status if b.error_status
            end
            errors.flatten!
            boolean = false
          end
        end

        unless retrieval.valid_config?
          @errors += retrieval.errors
          boolean = false
        end

        boolean
      end

      def generate_behaviors!
        raw_behaviors = Array(params["behaviors"] || params[:behaviors] || [])
        raw_behaviors.each_with_index do |behavior, index|
          @behaviors << Behavior.new(index:, gem_name:, **behavior)
        end
      end

      def generate_retreival!
        @retrieval = Helper::Retrieval.new(gem_name:, server: (params[:server] || params["server"]), git: (params[:git] || params["git"]))
      end

      def errors
        @errors ||= []
      end
    end
  end
end
