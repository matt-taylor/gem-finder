# frozen_string_literal: true

module GemFinder
  module Setup
    module Helper
      module OnFailure
        ALLOWED_ON_FAILURE = [:raise, :exit, DEFAULT_BEHAVIOR = :none]
        DEFAULT_LOG_LEVEL = :error

        def validate_on_failure
          on_failure = params["on_failure"]
          if on_failure.nil?
            @on_failure_log_level = DEFAULT_LOG_LEVEL
            @on_failure_behavior = DEFAULT_BEHAVIOR
            return true
          end

          if Hash === on_failure
            @on_failure_log_level = on_failure.fetch("log_level", DEFAULT_LOG_LEVEL)
            behavior = on_failure.fetch("behavior", DEFAULT_BEHAVIOR).to_sym rescue nil
            if ALLOWED_ON_FAILURE.include?(behavior)
              @on_failure_behavior = behavior
              return true
            else
              errors << "on_failure.behavior: Expected behavior to be in #{ALLOWED_ON_FAILURE}"
              return false
            end
          end

          errors << "on_failure: Expected value hash with :behavior and/or :log_level keys"
          false
        end

        def on_failure_default_message
          message = params.dig("on_failure", "message") rescue nil
          return message if message

          version_default_message
        end

        def on_failure_behavior(msg:)

        end

        def execute_on_failure!(behavior:, msg: on_failure_default_message)
          GemFinder.logger.public_send(@on_failure_log_level, "Validation failed for #{gem_name}. Current Version is #{current_version}. #{msg}")

          case @on_failure_behavior.to_sym
          when :raise
            raise ValidationError, "Validation failed for #{gem_name}. Current Version is #{current_version}. #{msg}"
          when :exit
            Kernel.exit(1)
          end
        end
      end
    end
  end
end
