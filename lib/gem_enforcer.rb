# frozen_string_literal: true

require "gem_enforcer/configuration"
require "gem_enforcer/errors"
require "gem_enforcer/retrieve"
require "gem_enforcer/setup"
require "gem_enforcer/version"

module GemEnforcer
  DEFAULT_SERVER_SOURCE = "https://rubygems.org"
  def self.configure
    yield configuration if block_given?
  end

  def self.configuration
    @configuration ||= GemEnforcer::Configuration.new
  end

  def self.configuration=(object)
    raise ConfigError, "Expected configuration to be a GemEnforcer::Configuration" unless object.is_a?(GemEnforcer::Configuration)

    @configuration = object
  end

  def self.github_access_token
    configuration.github_access_token
  end

  def self.logger
    configuration.logger
  end
end
