# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Validate do
  let(:instance) { described_class.new(name: gem_name, **params) }
  let(:params) do
    {
      **retrieval,
      **on_failure,
      **version,
    }
  end
  let(:gem_name) { "gem_name" }
  let(:retrieval) { { "server" => true } }
  let(:on_failure) { { } } # empty is a valid on_failure
  let(:version) { { "enforce_insync" => true } }
  let(:owner) { "matt-taylor" }
  before do
    # nullify log output
    GemEnforcer.configuration.logger = Logger.new("/dev/null")
  end

  describe "#initialize" do
    context "with invalid config" do
      shared_examples "invalid config errors" do
        it do
          expect(instance.error_status).to include(error_string)
        end

        it "validation status is false" do
          expect(instance.validation_status).to be(false)
        end
      end

      context "with invalid retrieval" do
        context "with server" do
          context "when false" do
            let(:retrieval) { { "server" => false } }
            let(:error_string) { "#{gem_name}.retrieval: Missing retrieval type. Expected `server` or `git`" }

            include_examples "invalid config errors"
          end

          context "when not a hash" do
            let(:retrieval) { { "server" => [] } }
            let(:error_string) { "#{gem_name}.retrieval.server: Missing source" }

            include_examples "invalid config errors"
          end

          context "when hash does not include source" do
            let(:retrieval) { { "server" => { "incorrect_key" => "not a source" } } }
            let(:error_string) { "#{gem_name}.retrieval.server: Missing source" }

            include_examples "invalid config errors"
          end
        end

        context "with git" do
          context "when not a hash" do
            let(:retrieval) { { "git" => [] } }
            let(:error_string) { "#{gem_name}.retrieval.git: Missing owner" }

            include_examples "invalid config errors"
          end

          context "when hash does not include owner" do
            let(:retrieval) { { "git" => { "incorrect_key" => "not a source" } } }
            let(:error_string) { "#{gem_name}.retrieval.git: Missing owner" }

            include_examples "invalid config errors"
          end
        end
      end

      context "with invalid on_failure" do
        context "when not a Hash" do
          let(:on_failure) { { "on_failure" => [] } }
          let(:error_string) { "#{gem_name}.on_failure: Expected value hash with :behavior and/or :log_level keys" }

          include_examples "invalid config errors"
        end

        context "with invalid behavior key" do
          let(:on_failure) { { "on_failure" => { "behavior" => described_class::ALLOWED_ON_FAILURE.sample.to_s + "x" } } }
          let(:error_string) { "#{gem_name}.on_failure.behavior: Expected behavior to be in #{described_class::ALLOWED_ON_FAILURE}" }

          include_examples "invalid config errors"
        end
      end

      context "with invalid version" do
        context "with both enforce_insync and validate_version" do
          let(:version) { { "enforce_insync" => true, "version_threshold" => { "releases" => 5} } }
          let(:error_string) { "#{gem_name}.version: Must only contain `enforce_insync` or `version_threshold`" }

          include_examples "invalid config errors"
        end

        context "when enforce_insync is false" do
          let(:version) { { "enforce_insync" => false } }
          let(:error_string) { "#{gem_name}.version.version_threshold: Expected keys to contain [#{described_class::ALLOWED_VERSION_REALEASE}] or #{described_class::ALLOWED_VERSION_SEMVER}" }

          include_examples "invalid config errors"
        end

        context "with invalid version_threshold" do
          context "when bad major" do
            let(:version) { { "version_threshold" => { "major" => "1", "minor" => 2, "patch" => 3 } } }
            let(:error_string) { "#{gem_name}.version.version_threshold.major: Expected value to be an Integer" }

            include_examples "invalid config errors"
          end

          context "when bad minor" do
            let(:version) { { "version_threshold" => { "major" => 1, "minor" => "2", "patch" => 3 } } }
            let(:error_string) { "#{gem_name}.version.version_threshold.minor: Expected value to be an Integer" }

            include_examples "invalid config errors"
          end

          context "when bad patch" do
            let(:version) { { "version_threshold" => { "major" => 1, "minor" => 2, "patch" => "3" } } }
            let(:error_string) { "#{gem_name}.version.version_threshold.patch: Expected value to be an Integer" }

            include_examples "invalid config errors"
          end

          context "when multiple are bad" do
            let(:version) { { "version_threshold" => { "major" => "1", "minor" => "2", "patch" => "3" } } }

            it "3 errors get added" do
              expect(instance.error_status.length).to eq(3)
            end
          end

          context "when releases are invalid" do
            let(:version) { { "version_threshold" => { "releases" => "6" } } }
            let(:error_string) { "#{gem_name}.version.version_threshold.releases: Expected value to be an Integer" }

            include_examples "invalid config errors"
          end
        end
      end
    end

    it do
      expect(instance.validation_status).to be(true)
    end
  end

  describe "#current_version" do
    subject(:current_version) { instance.current_version }

    context "when gem is loaded" do
      let(:gem_name) { "faraday" }

      it do
        is_expected.to eq(Gem::Version.new(Faraday::VERSION))
      end
    end

    context "when gem is not loaded" do
      let(:gem_name) { "invalid_gem_name" }

      it do
        is_expected.to be_nil
      end
    end
  end

  describe "#run_validation" do
    subject(:run_validation) { instance.run_validation! }

    let(:gem_name) { "rails_base" }

    context "when gem is not found" do
    end

    context "when version_execute fails" do
      before do
        allow(instance).to receive(:current_version).and_return(current_version)
      end

      let(:current_version) { Gem::Version.new("0.40.0") }

      shared_examples "version_execution logger expectations" do
        context "with default log_level" do
          it "outputs to default logger" do
            expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(/Validation failed for #{gem_name}. Current Version is #{current_version}/)

            subject
          end
        end

        context "with custom log_level" do
          let(:on_failure) { { "on_failure" => { "log_level" => "error" } } }

          it "outputs to custom logger" do
            expect(GemEnforcer.logger).to receive(:error).with(/Validation failed for #{gem_name}. Current Version is #{current_version}/)

            subject
          end
        end
      end

      shared_examples "version_execution behavior expectations" do
        before { allow(Kernel).to receive(:exit).with(1) }

        context "with behavior raise" do
          let(:on_failure) { { "on_failure" => { "behavior" => "raise" } } }

          it do
            expect { subject }.to raise_error(GemEnforcer::ValidationError, /Validation failed for #{gem_name}/)
          end
        end

        context "with behavior none" do
          let(:on_failure) { { "on_failure" => { "behavior" => "none" } } }

          it "does nothing" do
            expect { subject }.not_to raise_error
          end

          it do
            is_expected.to be(false)
          end
        end

        context "with behavior exit" do
          let(:on_failure) { { "on_failure" => { "behavior" => "exit" } } }

          it "exits" do
            expect(Kernel).to receive(:exit).with(1) # important to stub this out

            subject
          end
        end

        context "with custom behavior" do
        end
      end

      shared_examples "version_execution failures" do
        context "with git" do
          let(:retrieval) { { "git" => { "owner" => owner } } }

          include_examples "version_execution behavior expectations"
          include_examples "version_execution logger expectations"
        end

        context "with server" do
          let(:retrieval) { { "server" => true } }

          include_examples "version_execution behavior expectations"
          include_examples "version_execution logger expectations"
        end
      end

      context "with enforce_insync" do
        let(:version) { { "enforce_insync" => true } }

        include_examples "version_execution failures"
      end

      context "with releases" do
        let(:version) { { "version_threshold" => { "releases" => 2 } } }

        include_examples "version_execution failures"
      end

      context "with version_threshold" do
        let(:gem_name) { "rails" }
        let(:owner) { "rails" }
        let(:current_version) { Gem::Version.new("6.0.4") }
        let(:version) do
          {
            "version_threshold" => {
              "major" => major,
              "minor" => minor,
              "patch" => patch,
            }.compact
          }
        end

        let(:major) { 5 }
        let(:minor) { 5 }
        let(:patch) { 5 }

        context "when major version outdated" do
          let(:major) { 0 }

          it "logs correctly" do
            expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(/Failed to match major version threshold/)

            subject
          end

          include_examples "version_execution failures"
        end

        context "when minor version outdated" do
          let(:minor) { 0 }

          it "logs correctly" do
            expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(/Failed to match minor version threshold/)

            subject
          end

          include_examples "version_execution failures"
        end

        context "when patch version outdated" do
          let(:patch) { 0 }

          it "logs correctly" do
            expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(/Failed to match patch version threshold/)

            subject
          end

          include_examples "version_execution failures"
        end
      end
    end

    context "when version_execute succeeds" do
      before do
        allow(instance).to receive(:current_version).and_return(current_version)
      end
      let(:current_version) { Gem::Version.new("1") }

      shared_examples "version_execution success" do
        context "with git" do
          let(:retrieval) { { "git" => { "owner" => owner } } }

          it do
            expect { subject }.to_not raise_error
          end

          it do
            is_expected.to eq(true)
          end
        end

        context "with server" do
          let(:retrieval) { { "server" => true } }

          it do
            expect { subject }.to_not raise_error
          end

          it do
            is_expected.to eq(true)
          end
        end
      end

      context "with enforce_insync" do
        let(:version) { { "enforce_insync" => true } }

        include_examples "version_execution success"
      end

      context "with releases" do
        let(:version) { { "version_threshold" => { "releases" => 2 } } }

        include_examples "version_execution success"
      end

      context "with version_threshold" do
        let(:gem_name) { "rails" }
        let(:owner) { "rails" }
        let(:current_version) { Gem::Version.new("6.0.4") }
        let(:version) do
          {
            "version_threshold" => {
              "major" => major,
              "minor" => minor,
              "patch" => patch,
            }.compact
          }
        end

        let(:major) { nil }
        let(:minor) { nil }
        let(:patch) { nil }

        context "when only major provided" do
          let(:major) { 5 }

          include_examples "version_execution success"
        end

        context "when only minor provided" do
          let(:minor) { 5 }

          include_examples "version_execution success"
        end

        context "when only patch provided" do
          let(:patch) { 5 }

          include_examples "version_execution success"
        end
      end
    end
  end
end
