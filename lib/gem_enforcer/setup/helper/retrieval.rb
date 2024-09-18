# frozen_string_literal: true

module GemEnforcer
  module Setup
    module Helper
      class Retrieval
        attr_reader :gem_name, :server, :git, :retrieval_factory

        def initialize(gem_name:, server:, git:)
          @gem_name = gem_name
          @server = server
          @git = git
        end

        def valid_config?
          @valid_config ||= validate_config
        end

        def errors
          @errors ||= []
        end

        def retrieve_version_list
          unless valid_config?
            raise ConfigError, "Attempted to run validations with invalid Version Configurations"
          end

          retrieval_factory.gem_versions(name: gem_name).sort
        end

        private

        def validate_config
          if server && git
            errors << "retrieval: `server` and `git` keys present. Must only choose 1"
            return false
          end

          if server
            if server == true
              @source = GemEnforcer::DEFAULT_SERVER_SOURCE
            elsif String === server
              @source = server
            else
              errors << "server: Server retrieval provided. Expected `true` or a string of the rubygem source endpoint"
              return false
            end
            @retrieval_factory = Retrieve.server_retrieval_by_source(source: @source)
            return true
          end

          if git
            if String === git
              @owner = git
              @retrieval_factory = Retrieve.github_retrieval_by_owner(owner: git)
              return true
            else
              errors << "git: Git retrieval provided. Expected string of the owner/organization of the gem"
              return false
            end
          end

          errors << "retrieval: `server` and `git` keys are missing. Must provide 1 retrieval method"
          return false
        end
      end
    end
  end
end
