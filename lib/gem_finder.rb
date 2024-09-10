# frozen_string_literal: true

require "gem_finder/configuration"
require "gem_finder/errors"
require "gem_finder/retrieve"
require "gem_finder/setup"
require "gem_finder/version"

module GemFinder
  DEFAULT_SERVER_SOURCE = "https://rubygems.org"
  def self.configure
    yield configuration if block_given?
  end

  def self.configuration
    @configuration ||= GemFinder::Configuration.new
  end

  def self.configuration=(object)
    raise ConfigError, "Expected configuration to be a GemFinder::Configuration" unless object.is_a?(GemFinder::Configuration)

    @configuration = object
  end

  def self.github_access_token
    configuration.github_access_token
  end

  def self.logger
    configuration.logger
  end
end
