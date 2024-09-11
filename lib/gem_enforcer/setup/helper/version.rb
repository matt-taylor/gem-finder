# frozen_string_literal: true

module GemEnforcer
  module Setup
    module Helper
      module Version
        ALLOWED_VERSION_REALEASE = :releases
        ALLOWED_VERSION_SEMVER = [:major, :minor, :patch]
        ALLOWED_VERSION_THRESHOLD_KEYS = [ALLOWED_VERSION_REALEASE, *ALLOWED_VERSION_SEMVER]

        def version_default_message
          @default_version_message
        end

        def validate_version
          if params.keys.include?("enforce_insync") && params.keys.include?("version_threshold")
            errors << "version: Must only contain `enforce_insync` or `version_threshold`"
            return false
          end

          if params["enforce_insync"]
            @version_type = :enforce_insync
            @default_version_message = "Version must be the most recently released version."
            return true
          end

          @version_type = :version_threshold
          version_threshold_keys = params["version_threshold"]&.keys || []
          if version_threshold_keys.sort == [ALLOWED_VERSION_REALEASE.to_s].sort
            @version_threshold = :releases
            @default_version_message = "Version must be within #{params["version_threshold"]["releases"]} of the most recently released versions"
            _releases_validate
          elsif ALLOWED_VERSION_THRESHOLD_KEYS.any? { version_threshold_keys.include?(_1.to_s) }
            @version_threshold = :semver
            message = []
            message << "#{params["version_threshold"]["major"]} major versions"  if params["version_threshold"]["major"]
            message << "#{params["version_threshold"]["minor"]} minor versions"  if params["version_threshold"]["minor"]
            message << "#{params["version_threshold"]["patch"]} patch versions"  if params["version_threshold"]["patch"]
            @default_version_message = "Version must be within #{message.join(" and ")} of the most recent release."
            _semver_validate
          else
            errors << "version.version_threshold: Expected keys to contain [#{ALLOWED_VERSION_REALEASE}] or #{ALLOWED_VERSION_SEMVER}"
            false
          end
        end

        def _semver_validate
          boolean = true
          if major = params["version_threshold"]["major"]
            unless Integer === major
              boolean = false
              errors << "version.version_threshold.major: Expected value to be an Integer"
            end
          end

          if minor = params["version_threshold"]["minor"]
            unless Integer === minor
              boolean = false
              errors << "version.version_threshold.minor: Expected value to be an Integer"
            end
          end

          if patch = params["version_threshold"]["patch"]
            unless Integer === patch
              boolean = false
              errors << "version.version_threshold.patch: Expected value to be an Integer"
            end
          end

          boolean
        end

        def _releases_validate
          release_count = params["version_threshold"]["releases"]
          unless Integer === release_count
            errors << "version.version_threshold.releases: Expected value to be an Integer"
            return false
          end

          true
        end

        def version_execute?(version_list:)
          if @version_type == :enforce_insync
            __validate_enforce_insync?(version_list:)
          else
            if @version_threshold == :releases
              __validate_version_threshold_releases?(version_list:)
            else
              __validate_version_threshold_semver?(version_list:)
            end
          end
        end

        def __validate_version_threshold_semver?(version_list:)
          if max_major_versions_behind = params.dig("version_threshold", "major")
            return false unless __threshold_semver_distance(type: :major, number: current_version.segments[0], list: version_list.map { _1.segments[0] }, threshold: max_major_versions_behind)
          end

          if max_minor_versions_behind = params.dig("version_threshold", "minor")
            # Select only the minor versions that match the major version
            current_major_version = current_version.segments[0]
            minor_version_check_list = version_list.select { _1.segments[0] == current_major_version }.map { _1.segments[1] }
            return false unless __threshold_semver_distance(type: :minor, number: current_version.segments[1], list: minor_version_check_list, threshold: max_minor_versions_behind)
          end

          if max_patch_versions_behind = params.dig("version_threshold", "patch")
            # Select only the patch versions that match the major version
            current_major_minor_version = current_version.segments[0..1]
            patch_version_check_list = version_list.select { _1.segments[0..1] == current_major_minor_version }.map { _1.segments[2] }
            return false unless __threshold_semver_distance(type: :patch, number: current_version.segments[2], list: patch_version_check_list, threshold: max_patch_versions_behind)
          end

          true
        end

        def __threshold_semver_distance(type:, number:, list:, threshold:)
          # remove duplicates ans sort in highest to lowest number
          uniq_list = list.uniq.sort.reverse

          # get the position in the sorted array
          position_in_sorted_array = uniq_list.find_index(number)

          # if position is less than or equal to the threshold, we are good
          # otherwise, it is out of compliance
          return true if position_in_sorted_array <= threshold

          @default_version_message += " Failed to match #{type} version threshold"

          false
        end

        def __validate_version_threshold_releases?(version_list:)
          releases_behind = params.dig("version_threshold", "releases").to_i

          min_version_allowed = version_list[-releases_behind]
          current_version >= min_version_allowed
        end

        def __validate_enforce_insync?(version_list:)
          max_version = version_list.max
          return true if current_version >= max_version

          @default_version_message += " Please upgrade to at least v#{max_version}"

          false
        end
      end
    end
  end
end
