# frozen_string_literal: true

module GemEnforcer
  module Setup
    module Helper
      class VersionEnforcer
        attr_reader :gem_name, :version_enforce, :error_validation_message

        ALLOWED_VERSION_INSYNC = :insync
        ALLOWED_VERSION_REALEASE = :releases
        ALLOWED_VERSION_SEMVER = [MAJOR = :major, MINOR = :minor, PATCH = :patch]

        def initialize(gem_name:, version_enforce:)
          @gem_name = gem_name
          @version_enforce = version_enforce.transform_keys(&:to_sym) rescue nil
        end

        def valid_config?
          @valid_config ||= validate_config
        end

        def valid_gem_versions?(version_list:, version:)
          unless valid_config?
            raise ConfigError, "Attempted to run validations with invalid Version Configurations"
          end

          return true if version.nil?

          min_to_max_version_sorted_list = version_list.sort
          case @version_type
          when :insync
            __validation_insync(version_list: min_to_max_version_sorted_list, version:)
          when :releases
            __validation_releases(version_list: min_to_max_version_sorted_list, version:)
          when :semver
            __validation_semver(version_list: min_to_max_version_sorted_list, version:)
          end
        end

        def errors
          @errors ||= []
        end

        def versions_behind(version_list:, version:)
          version_list.sort.reverse.find_index(version)
        end

        private

        def __validation_insync(version_list:, version:)
          max_version = version_list.max
          return true if version >= max_version

          @error_validation_message = "[#{gem_name}] Enforcer expects the most recent version. Version #{version}. Most Recent version #{max_version}"

          false
        end

        def __validation_releases(version_list:, version:)
          releases_behind = version_enforce[ALLOWED_VERSION_REALEASE]
          min_version_allowed = version_list[-releases_behind]
          return true if version >= min_version_allowed

          if index = version_list.sort.reverse.find_index(version)
            version_text = "Version [#{version}] is the #{index} oldest version."
          else
            version_text = "Version [#{version}] is the was not found in the provided list."
          end

          @error_validation_message = "[#{gem_name}] Enforcer expects the version to be within the most recent #{releases_behind} versions. #{version_text}"
          false
        end

        def __validation_semver(version_list:, version:)
          if max_major_versions_behind = version_enforce[:major]
            if error = __threshold_semver_distance(type: :major, number: version.segments[0], list: version_list.map { _1.segments[0] }, threshold: max_major_versions_behind, version: version)
              @error_validation_message = error
              return false
            end
          end

          if max_minor_versions_behind = version_enforce[:minor]
            # Select only the minor versions that match the major version
            current_major_version = version.segments[0]
            minor_version_check_list = version_list.select { _1.segments[0] == current_major_version }.map { _1.segments[1] }
            if error = __threshold_semver_distance(type: :minor, number: version.segments[1], list: minor_version_check_list, threshold: max_minor_versions_behind, version: version)
              @error_validation_message = error
              return false
            end
          end

          if max_patch_versions_behind = version_enforce[:patch]
            # Select only the patch versions that match the major.minor version
            current_major_minor_version = version.segments[0..1]
            patch_version_check_list = version_list.select { _1.segments[0..1] == current_major_minor_version }.map { _1.segments[2] }
            if error = __threshold_semver_distance(type: :patch, number: version.segments[2], list: patch_version_check_list, threshold: max_patch_versions_behind, version: version)
              @error_validation_message = error
              return false
            end
          end

          true
        end

        def __threshold_semver_distance(type:, number:, list:, threshold:, version:)
          # remove duplicates ans sort in highest to lowest number
          uniq_list = list.uniq.sort.reverse

          # get the position in the sorted array
          position_in_sorted_array = uniq_list.find_index(number)

          # if position is less than or equal to the threshold, we are good
          # otherwise, it is out of compliance
          return nil if position_in_sorted_array <= threshold

          "[#{gem_name}] Enforcer expects the version to be within #{threshold} #{type} versions of the most recent version. Version is #{version}"
        end

        def validate_config
          unless Hash === version_enforce
            errors << "version_enforce: Must be a hash containing [#{ALLOWED_VERSION_INSYNC}] or [#{ALLOWED_VERSION_REALEASE}] or any of [#{ALLOWED_VERSION_SEMVER}]"
            return false
          end

          if version_enforce.keys.include?(ALLOWED_VERSION_INSYNC)
            @version_type = :insync
            __validate_config_insync
          elsif version_enforce.keys.include?(ALLOWED_VERSION_REALEASE)
            @version_type = :releases
            __validate_config_releases
          elsif version_enforce.keys.any? { ALLOWED_VERSION_SEMVER.include?(_1) }
            @version_type = :semver
            __validate_config_semver
          else
            errors << "version_enforce: Invalid config. Hash must contain [#{ALLOWED_VERSION_INSYNC}] or [#{ALLOWED_VERSION_REALEASE}] or any of [#{ALLOWED_VERSION_SEMVER}]"
            false
          end
        end

        def __validate_config_insync
          return false unless validate_expected_keys(ALLOWED_VERSION_INSYNC, "insync")

          return true if version_enforce[ALLOWED_VERSION_INSYNC]

          errors << "version_enforce.#{ALLOWED_VERSION_INSYNC}: When key is present, value must be true. Received [#{version_enforce[ALLOWED_VERSION_INSYNC]}]"
          false
        end

        def __validate_config_releases
          return false unless validate_expected_keys(ALLOWED_VERSION_REALEASE, ALLOWED_VERSION_REALEASE)

          validate_integer(version_enforce[ALLOWED_VERSION_REALEASE], ALLOWED_VERSION_REALEASE)
        end

        def __validate_config_semver
          return false unless validate_expected_keys(ALLOWED_VERSION_SEMVER, "SemVer")

          boolean = true
          boolean &= validate_integer(version_enforce[MAJOR], "major") if version_enforce[MAJOR]
          boolean &= validate_integer(version_enforce[MINOR], "minor") if version_enforce[MINOR]
          boolean &= validate_integer(version_enforce[PATCH], "patch") if version_enforce[PATCH]

          boolean
        end

        def validate_expected_keys(allowed, type)
          disallowed_keys = version_enforce.keys - Array(allowed)

          return true if disallowed_keys.length == 0

          errors << "version_enforce: Unexpected keys present for `#{type}`. Allowed keys [#{allowed}] but received #{version_enforce.keys}. [#{disallowed_keys}] is not allowed"
          false
        end

        def validate_integer(val, dig)
          return true if Integer === val

          errors << "version_enforce.#{dig}: Expected value to be an Integer. Recieved type #{val.class} [#{val}]"
          false
        end
      end
    end
  end
end
