# frozen_string_literal: true

require "octokit"

module GemFinder
  module Retrieve
    class GitTag
      def initialize(owner:, access_token: GemFinder.github_access_token)
        @access_token = access_token
        @owner = owner
      end

      def gem_versions(name:)
        repo_name = "#{@owner}/#{name}"
        releases = client.releases(repo_name, { per_page: 50 })
        while next_page_href = client.last_response.rels[:next]&.href
          releases.concat(client.get(next_page_href, { per_page: 50 }))
        end

        releases.map { Gem::Version.new(_1.tag_name.gsub(/.*?(?=\d*\.)/im, "")) }.compact
      end

      def client
        @client ||= ::Octokit::Client.new(access_token: @access_token)
      end
    end
  end
end
