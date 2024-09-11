# frozen_string_literal: true

module GemEnforcer
  module Setup
    module Helper
      module Retrieval
        def validate_retrieval
          if params["server"]
            @retrieval_method = :server
            server_result = _server_validate
            @factory_version_list = Retrieve.server_retrieval_by_source(source: @retrieval_source)

            server_result
          elsif params["git"]
            @retrieval_method = :git
            git_result = _git_validate
            @factory_version_list = Retrieve.github_retrieval_by_owner(owner: @retrieval_owner)

            git_result
          else
            errors << "retrieval: Missing retrieval type. Expected `server` or `git`"
            false
          end
        end

        def retrieve_version_list
          @factory_version_list.gem_versions(name: @gem_name).sort
        end

        def _server_validate
          server = params.dig("server")

          if server == true
            @retrieval_source = GemEnforcer::DEFAULT_SERVER_SOURCE
            return true
          end

          if Hash === server && server["source"]
            @retrieval_source = server["source"]
            return true
          end

          errors << "retrieval.server: Missing source"
          false
        end

        def _git_validate
          git = params.dig("git")
          if Hash === git && git["owner"]
            @retrieval_owner = git["owner"]
            return true
          end

          errors << "retrieval.git: Missing owner"
          false
        end
      end
    end
  end
end
