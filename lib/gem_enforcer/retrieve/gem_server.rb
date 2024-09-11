# frozen_string_literal: true

require "faraday"

module GemEnforcer
  module Retrieve
    class GemServer
      def initialize(source: DEFAULT_SOURCE)
        @source = source
      end

      def gem_versions(name:)
        raw_gem_versions = raw_server_versions.select { _1.match?(/^#{name} /) }
        return [] if raw_gem_versions.nil? || raw_gem_versions.empty?

        versions = raw_gem_versions.map do |metadata|
          raw_name, raw_version_list, _sha = metadata.split(" ")
          next if raw_name != name

          raw_version_list.split(",").map { Gem::Version.new(_1) }
        end.flatten.compact.uniq

        versions
      end

      # expensive call .. do this once gem source
      def raw_server_versions
        @server_versions ||= begin
          api_call = Faraday.new(url: @source).get("versions")
          api_call.body.split("\n")
        end
      end
    end
  end
end
