# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Helper::Retrieval do
  let(:instance) { described_class.new(gem_name:, server:, git:) }
  let(:gem_name) { "rails_base" }
  let(:server) { nil }
  let(:git) { nil }

  describe "#valid_config?" do
    subject(:valid_config) { instance.valid_config? }

    context "when invalid" do
      context "when both present" do
        let(:server) { true }
        let(:git) { "matt-taylor" }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("retrieval: `server` and `git` keys present")
        end
      end

      context "when both not present" do
        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("retrieval: `server` and `git` keys are missing")
        end
      end

      context "with invalid server" do
        let(:server) { [] }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("server: Server retrieval provided")
        end
      end

      context "with invalid git" do
        let(:git) { true }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("git: Git retrieval provided")
        end
      end
    end

    context "when valid" do
      context "with server" do
        context "with true" do
          let(:server) { true }

          it "sets retrieval_factory" do
            valid_config

            expect(instance.retrieval_factory).to be_a(GemEnforcer::Retrieve::GemServer)
          end

          it do
            is_expected.to be(true)
          end

          it do
            valid_config

            expect(instance.errors.length).to eq(0)
          end
        end

        context "with source" do
          let(:server) { "https://rubygems.org" }

          it "sets retrieval_factory" do
            valid_config

            expect(instance.retrieval_factory).to be_a(GemEnforcer::Retrieve::GemServer)
          end

          it do
            is_expected.to be(true)
          end

          it do
            valid_config

            expect(instance.errors.length).to eq(0)
          end
        end
      end

      context "with git" do
        let(:git) { "matt-taylor" }

        it "sets retrieval_factory" do
          valid_config

          expect(instance.retrieval_factory).to be_a(GemEnforcer::Retrieve::GitTag)
        end

        it do
          is_expected.to be(true)
        end

        it do
          valid_config

          expect(instance.errors.length).to eq(0)
        end
      end
    end
  end

  describe "#retrieve_version_list" do
    subject(:retrieve_version_list) { instance.retrieve_version_list }

    context "with invalid config" do
      let(:server) { true }
      let(:git) { "matt-taylor" }

      it do
        expect { retrieve_version_list }.to raise_error(GemEnforcer::ConfigError, /Attempted to run validations with invalid Version Configurations/)
      end
    end

    context "with valid config" do
      context "with git" do
        let(:git) { "matt-taylor" }

        it do
          is_expected.to all(be_a(Gem::Version))
        end
      end

      context "with server" do
        let(:server) { true }

        it do
          is_expected.to all(be_a(Gem::Version))
        end
      end
    end
  end
end
