# frozen_string_literal: true

require "gem_enforcer/retrieve/gem_server"
require "gem_enforcer/retrieve/git_tag"

module GemEnforcer
  module Retrieve
    module_function

    def server_retrieval_by_source(source:)
      @server_retrieval_by_source ||= {}

      return @server_retrieval_by_source[source] if @server_retrieval_by_source[source]

      @server_retrieval_by_source[source] = GemServer.new(source: source)
      @server_retrieval_by_source[source]
    end

    def github_retrieval_by_owner(owner:)
      @github_retrieval_by_owner ||= {}

      return @github_retrieval_by_owner[owner] if @github_retrieval_by_owner[owner]

      @github_retrieval_by_owner[owner] = GitTag.new(owner: owner)
      @github_retrieval_by_owner[owner]
    end
  end
end
