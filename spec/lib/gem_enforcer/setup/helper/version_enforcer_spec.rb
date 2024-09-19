# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Helper::VersionEnforcer do
  let(:instance) { described_class.new(gem_name:, version_enforce:) }
  let(:gem_name) { "faraday" }

  describe ".initialize" do
    subject { instance }

    context "when version_enforce is not a hash" do
      let(:version_enforce) { [] }

      it do
        expect { subject }.to_not raise_error
      end

      it do
        expect(subject.version_enforce).to be_nil
      end

      it do
        expect(subject.gem_name).to eq(gem_name)
      end
    end

    context "when version_enforce is a hash" do
      let(:version_enforce) { {} }

      it do
        expect(subject.gem_name).to eq(gem_name)
      end

      it do
        expect(subject.version_enforce).to be_a(Hash)
      end

      it do
        expect(subject.version_enforce).to be_empty
      end

      context "with string keys" do
        let(:version_enforce) { { "string" => 1, "string_2" => 2} }

        it do
          expect(subject.gem_name).to eq(gem_name)
        end

        it do
          expect(subject.version_enforce).to be_a(Hash)
        end

        it do
          expect(subject.version_enforce[:string]).to eq(1)
        end

        it do
          expect(subject.version_enforce[:string_2]).to eq(2)
        end
      end

      context "with symbol keys" do
        let(:version_enforce) { { string: 1, string_2: 2 } }

        it do
          expect(subject.gem_name).to eq(gem_name)
        end

        it do
          expect(subject.version_enforce).to be_a(Hash)
        end

        it do
          expect(subject.version_enforce[:string]).to eq(1)
        end

        it do
          expect(subject.version_enforce[:string_2]).to eq(2)
        end
      end
    end
  end

  describe "#valid_config?" do
    subject(:valid_config) { instance.valid_config? }

    context "with invalid config" do
      context "when not a hash" do
        let(:version_enforce) { [] }

        it do
          expect(valid_config).to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("Must be a hash containing")
        end
      end

      context "with no valid keys" do
        let(:version_enforce) { { invalid: :key } }

        it do
          expect(valid_config).to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("Invalid config. Hash must contain")
        end
      end

      context "with insync" do
        context "with extra key" do
          let(:version_enforce) { { insync: true, invalid_key: true } }

          it do
            expect(valid_config).to eq(false)
          end

          it "correct errors" do
            valid_config

            expect(instance.errors.length).to eq(1)
            expect(instance.errors.first).to include("Unexpected keys present for `insync`")
          end
        end

        context "when set to false" do
          let(:version_enforce) { { insync: false } }

          it do
            expect(valid_config).to eq(false)
          end

          it "correct errors" do
            valid_config

            expect(instance.errors.length).to eq(1)
            expect(instance.errors.first).to include("When key is present, value must be true")
          end
        end
      end

      context "with releases" do
        context "with extra key" do
          let(:version_enforce) { { releases: 5, major: 0 } }

          it do
            expect(valid_config).to eq(false)
          end

          it "correct errors" do
            valid_config

            expect(instance.errors.length).to eq(1)
            expect(instance.errors.first).to include("Unexpected keys present for `releases`")
          end
        end

        context "when not an integer" do
          let(:version_enforce) { { releases: "1" } }

          it do
            expect(valid_config).to eq(false)
          end

          it "correct errors" do
            valid_config

            expect(instance.errors.length).to eq(1)
            expect(instance.errors.first).to include("Expected value to be an Integer")
          end
        end
      end

      context "with SemVer" do
        context "with extra key" do
          let(:version_enforce) { { major: 0, security: 2 } }

          it do
            expect(valid_config).to eq(false)
          end

          it "correct errors" do
            valid_config

            expect(instance.errors.length).to eq(1)
            expect(instance.errors.first).to include("Unexpected keys present for `SemVer`")
          end
        end

        context "when not an integer" do
          let(:version_enforce) { { major:, minor:, patch: }.compact }
          let(:major) { nil }
          let(:minor) { nil }
          let(:patch) { nil }

          context "with patch" do
            let(:patch) { "s" }

            it do
              expect(valid_config).to eq(false)
            end

            it "correct errors" do
              valid_config

              expect(instance.errors.length).to eq(1)
              expect(instance.errors.first).to include("version_enforce.patch: Expected value to be an Integer")
            end
          end

          context "with minor" do
            let(:minor) { "s" }

            it do
              expect(valid_config).to eq(false)
            end

            it "correct errors" do
              valid_config

              expect(instance.errors.length).to eq(1)
              expect(instance.errors.first).to include("version_enforce.minor: Expected value to be an Integer")
            end

            context "with minor.patch" do
              let(:patch) { "t" }

              it do
                expect(valid_config).to eq(false)
              end

              it "correct errors" do
                valid_config

                expect(instance.errors.length).to eq(2)
                expect(instance.errors[0]).to include("version_enforce.minor: Expected value to be an Integer")
                expect(instance.errors[1]).to include("version_enforce.patch: Expected value to be an Integer")
              end
            end
          end

          context "with major" do
            let(:major) { "s" }

            it do
              expect(valid_config).to eq(false)
            end

            it "correct errors" do
              valid_config

              expect(instance.errors.length).to eq(1)
              expect(instance.errors.first).to include("version_enforce.major: Expected value to be an Integer")
            end

            context "with major.minor" do
              let(:minor) { "t" }

              it do
                expect(valid_config).to eq(false)
              end

              it "correct errors" do
                valid_config

                expect(instance.errors.length).to eq(2)
                expect(instance.errors[0]).to include("version_enforce.major: Expected value to be an Integer")
                expect(instance.errors[1]).to include("version_enforce.minor: Expected value to be an Integer")
              end

              context "with major.minor.patch" do
                let(:patch) { "u" }

                it do
                  expect(valid_config).to eq(false)
                end

                it "correct errors" do
                  valid_config

                  expect(instance.errors.length).to eq(3)
                  expect(instance.errors[0]).to include("version_enforce.major: Expected value to be an Integer")
                  expect(instance.errors[1]).to include("version_enforce.minor: Expected value to be an Integer")
                  expect(instance.errors[2]).to include("version_enforce.patch: Expected value to be an Integer")
                end
              end
            end
          end
        end
      end
    end

    context "with valid config" do
      context "with insync" do
        let(:version_enforce) { { insync: true } }

        it do
          expect(valid_config).to eq(true)
        end

        it "no errors" do
          valid_config

          expect(instance.errors.length).to eq(0)
        end
      end

      context "with releases" do
        let(:version_enforce) { { releases: 5 } }

        it do
          expect(valid_config).to eq(true)
        end

        it "no errors" do
          valid_config

          expect(instance.errors.length).to eq(0)
        end
      end

      context "with SemVer" do
        let(:version_enforce) { { major:, minor:, patch: }.compact }
        let(:major) { nil }
        let(:minor) { nil }
        let(:patch) { nil }

        context "with major" do
          let(:major) { 1 }
          it do
            expect(valid_config).to eq(true)
          end

          it "no errors" do
            valid_config

            expect(instance.errors.length).to eq(0)
          end

          context "with major.minor" do
            let(:minor) { 2 }

            it do
              expect(valid_config).to eq(true)
            end

            it "no errors" do
              valid_config

              expect(instance.errors.length).to eq(0)
            end

            context "with major.minor.patch" do
              let(:patch) { 3 }

              it do
                expect(valid_config).to eq(true)
              end

              it "no errors" do
                valid_config

                expect(instance.errors.length).to eq(0)
              end
            end
          end
        end
      end
    end
  end

  describe "#valid_gem_versions?" do
    subject(:valid_gem_versions) { instance.valid_gem_versions?(version_list:, version:) }
    let(:major_versions) { 5 }
    let(:minor_versions) { 4 }
    let(:patch_versions) { 3 }
    let(:version_list) do
      major_versions.times.map do |maj|
        minor_versions.times.map do |min|
          patch_versions.times.map do |pat|
            Gem::Version.new("#{maj + 1}.#{min}.#{pat}")
          end
        end
      end.flatten.shuffle #shuffle to ensure the class validations methods sort things correctly
    end
    let(:version) { version_list.sample }

    context "with invalid config" do
      let(:version_enforce) { { invalid: "things" } }

      it do
        expect { valid_gem_versions }.to raise_error(GemEnforcer::ConfigError, /Attempted to run validations/)
      end
    end

    context "with success" do
      context "with insync" do
        let(:version_enforce) { { insync: true } }
        let(:version) { version_list.max }

        it do
          is_expected.to eq(true)
        end
      end

      context "with releases" do
        let(:version_enforce) { { releases: } }
        let(:releases) { 5 }
        let(:version) { version_list.sort[-releases] }

        it do
          is_expected.to eq(true)
        end
      end

      context "with SemVer" do
        let(:version_enforce) { { major:, minor:, patch: }.compact }
        let(:major) { nil }
        let(:minor) { nil }
        let(:patch) { nil }

        context "when major is present" do
          let(:major) { 0 }
          let(:version) { Gem::Version.new("#{major_versions}.0.0") }

          it do
            is_expected.to eq(true)
          end

          context "when major.minor present" do
            let(:minor) { 0 }
            let(:version) { Gem::Version.new("#{major_versions}.#{minor_versions - 1}.0") }

            it do
              is_expected.to eq(true)
            end

            context "when major.minor.patch present" do
              let(:patch) { 0 }
              let(:version) { Gem::Version.new("#{major_versions}.#{minor_versions - 1}.#{patch_versions - 1}") }

              it do
                is_expected.to eq(true)
              end
            end
          end
        end
      end
    end

    context "with failure" do
      context "with insync" do
        let(:version_enforce) { { insync: true } }
        let(:version) { version_list.min }

        it do
          is_expected.to eq(false)
        end

        it "correct messaging" do
          valid_gem_versions

          expect(instance.error_validation_message).to eq("[#{gem_name}] Enforcer expects the most recent version. Version #{version}. Most Recent version #{version_list.max}")
        end
      end

      context "with releases" do
        let(:version_enforce) { { releases: } }
        let(:releases) { 5 }
        let(:version) { version_list.sort[-(releases+1)] }
        let(:version_text) do
          "Enforcer expects the version to be within the most recent #{releases} versions. "
        end

        it do
          is_expected.to eq(false)
        end

        it "correct messaging" do
          valid_gem_versions

          expect(instance.error_validation_message).to include(version_text)
        end

        context "when version is not found" do
          let(:version) { Gem::Version.new("0.0.0") }

          it do
            is_expected.to eq(false)
          end

          it "correct messaging" do
            valid_gem_versions

            expect(instance.error_validation_message).to include("Version [#{version}] is the was not found in the provided list.")
          end
        end
      end

      context "with SemVer" do
        let(:version_enforce) { { major:, minor:, patch: }.compact }
        let(:major) { nil }
        let(:minor) { nil }
        let(:patch) { nil }

        context "when major is present" do
          let(:major) { 0 }
          let(:version) { Gem::Version.new("#{major_versions - 1}.0.0") }

          it do
            is_expected.to eq(false)
          end

          it "correct messaging" do
            valid_gem_versions

            expect(instance.error_validation_message).to include("Enforcer expects the version to be within #{major} major versions of the most recent version")
          end

          context "when major.minor present" do
            let(:minor) { 0 }
            let(:version) { Gem::Version.new("#{major_versions}.#{minor_versions - 2}.0") }

            it do
              is_expected.to eq(false)
            end

            it "correct messaging" do
              valid_gem_versions

              expect(instance.error_validation_message).to include("Enforcer expects the version to be within #{minor} minor versions of the most recent version")
            end

            context "when major.minor.patch present" do
              let(:patch) { 0 }
              let(:version) { Gem::Version.new("#{major_versions}.#{minor_versions - 1}.#{patch_versions - 2}") }

              it do
                is_expected.to eq(false)
              end

              it "correct messaging" do
                valid_gem_versions

                expect(instance.error_validation_message).to include("Enforcer expects the version to be within #{patch} patch versions of the most recent version")
              end
            end
          end
        end
      end
    end
  end
end
