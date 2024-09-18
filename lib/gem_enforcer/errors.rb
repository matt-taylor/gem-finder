# frozen_string_literal: true

module GemEnforcer
  class Error < StandardError; end
  class ConfigError < Error; end
  class ValidationError < Error; end
end
