# frozen_string_literal: true

module GemEnforcer
  module Setup
    module Helper
      class OnFailure
        attr_reader :gem_name, :on_failure

        ALLOWED_KEYS = [LOG_LEVEL = :log_level, FAILURE_BEHAVIOR = :behavior, MESSAGE = :message]
        ALLOWED_FAILURE_BEHAVIOR = [:raise, :exit, DEFAULT_BEHAVIOR = :none]
        DEFAULT_LOG_LEVEL = :error

        def initialize(gem_name:, on_failure:)
          @gem_name = gem_name
          @on_failure = on_failure.transform_keys(&:to_sym) rescue on_failure
        end

        def valid_config?
          @valid_config ||= validate_config
        end

        def errors
          @errors ||= []
        end

        def run_on_failure!(message:, **params)
          unless valid_config?
            raise ConfigError, "Attempted to run on_failure with an invalid config."
          end

          send_message = (provided_message || message) % params
          GemEnforcer.logger.public_send(on_failure_log_level, send_message)

          case on_failure_behavior.to_sym
          when :raise
            raise ValidationError, send_message
          when :exit
            Kernel.exit(1)
          end

          true
        end

        private

        def on_failure_behavior
          (on_failure[FAILURE_BEHAVIOR] || DEFAULT_BEHAVIOR) rescue DEFAULT_BEHAVIOR
        end

        def on_failure_log_level
          (on_failure[LOG_LEVEL] || DEFAULT_LOG_LEVEL) rescue DEFAULT_LOG_LEVEL
        end

        def provided_message
          on_failure[MESSAGE] rescue nil
        end

        def validate_config
          return true if on_failure.nil?

          unless Hash === on_failure
            errors << "on_failure: Expected to contain a Hash. Contained a [#{on_failure.class}]"
            return false
          end

          disallowed_keys = on_failure.keys - ALLOWED_KEYS
          if disallowed_keys.length > 0
            errors << "on_failure: Contained unexpected keys. Only #{ALLOWED_KEYS} are allowed. Found #{disallowed_keys}"
            return false
          end

          if on_failure[FAILURE_BEHAVIOR] && ALLOWED_FAILURE_BEHAVIOR.none? { _1 == on_failure[FAILURE_BEHAVIOR].to_sym }
            errors << "on_failure.#{FAILURE_BEHAVIOR}: Value must be one of #{ALLOWED_FAILURE_BEHAVIOR}. Provided [#{on_failure[FAILURE_BEHAVIOR]}] "
            return false
          end

          true
        end
      end
    end
  end
end
