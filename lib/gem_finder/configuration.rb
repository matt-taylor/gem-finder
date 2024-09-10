# frozen_string_literal: true

require "class_composer"
require "logger"
require "gem_finder/errors"

module GemFinder
  class Configuration
    include ClassComposer::Generator

    GITHUB_ACCESS_TOKEN = Proc.new do
      token = ENV.fetch("GITHUB_TOKEN") do
        ENV.fetch("BUNDLE_GITHUB__COM") do
          raise GemFinder::Error, "Expected access token in `GITHUB_TOKEN` or `BUNDLE_GITHUB__COM`"
        end
      end
      if token.end_with?(":x-oauth-basic")
        token.split(":x-oauth-basic")[0]
      else
        token
      end
    end

    DEFAULT_YAML_PATH = Proc.new do
      if defined?(Rails)
        "#{Rails.root}/config/gem_finder.yml"
      else
        "/gem/gem_finder.yml"
      end
    end

    add_composer :github_access_token, allowed: String, default: GITHUB_ACCESS_TOKEN.()
    add_composer :yml_config_path, allowed: String, default: DEFAULT_YAML_PATH.()
    add_composer :raise_on_invalid_config, allowed: [TrueClass, FalseClass], default: true
    add_composer :logger, allowed: [Logger, (TTY::Logger if defined?(TTY::Logger))].compact, default: Logger.new(STDOUT)
  end
end
