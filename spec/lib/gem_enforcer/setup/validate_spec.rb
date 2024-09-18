# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Validate do
  let(:instance) { described_class.new(name: gem_name, **params) }
  let(:params) do
    {
      behaviors:,
      server:,
      git:,
    }.compact
  end
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
  let(:gem_name) { "rails_base" }
  let(:message) { "this is a custom message" }
  let(:on_failure) { { } } # empty is a valid on_failure
  let(:version_enforce) { { insync: true } }
  let(:server) { true }
  let(:git) { "matt-taylor" }
  let(:custom_behavior) do
    {
      on_failure:,
      version_enforce:,
    }.compact
  end
  let(:behaviors) { [custom_behavior]}
  let(:exit_behavior) do
    {
      on_failure: { behavior: :exit },
      version_enforce:,
    }
  end
  let(:raise_behavior) do
    {
      on_failure: { behavior: :raise },
      version_enforce:,
    }
  end
  let(:default_behavior) do
    {
      version_enforce:,
    }
  end
  before do
    # nullify log output
    GemEnforcer.configuration.logger = Logger.new("/dev/null")
  end

  describe "#valid_config?" do
    subject(:valid_config) { instance.valid_config? }

    context "when invalid" do
      context "with invalid failure" do
      end

      context "with invalid version" do
        let(:version_enforce) { { insync: false } }
        let(:git) { nil }
        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(1)
          expect(instance.error_status.first).to include("#{gem_name}.behaviors[0].version_enforce.insync")
        end
      end

      context "with invalid retrieval" do
        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(1)
          expect(instance.error_status.first).to include("#{gem_name}.retrieval")
        end
      end

      context "when no behaviors" do
        let(:behaviors) { [] }
        let(:git) { nil }
        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(1)
          expect(instance.error_status.first).to include("#{gem_name}.behaviors: At least 1 behavior is expected")
        end
      end
    end

    context "when valid" do
      context "with server" do
        let(:git) { nil }

        it do
          is_expected.to eq(true)
        end

        it do
          valid_config

          expect(instance.error_status).to be_nil
        end
      end

      context "with git" do
        let(:server) { nil }

        it do
          is_expected.to eq(true)
        end

        it do
          valid_config

          expect(instance.error_status).to be_nil
        end
      end
    end
  end

  describe "#run_validation!" do
    subject(:run_validation) { instance.run_validation! }

    let(:retrieval) { instance_double(GemEnforcer::Setup::Helper::Retrieval, retrieve_version_list: version_list, valid_config?: true)}

    shared_examples "with different behaviors" do
      context "with none (Default)" do
        let(:behaviors) { [default_behavior] }

        it do
          is_expected.to eq(false)
        end

        it "does not raise or exit" do
          expect(Kernel).to_not receive(:exit)

          expect { subject }.to_not raise_error
        end
      end

      context "with raise" do
        let(:behaviors) { [raise_behavior] }

        it "raises error" do
          expect { subject }.to raise_error(GemEnforcer::ValidationError, /Enforcer expects the most recent version/)
        end

        it "does not exit" do
          expect(Kernel).to_not receive(:exit)

          expect { subject }.to raise_error(StandardError)
        end
      end

      context "with exit" do
        let(:behaviors) { [exit_behavior] }
        before { allow(Kernel).to receive(:exit) }

        it "does not raise error" do
          expect { subject }.to_not raise_error
        end

        it "exits" do
          expect(Kernel).to receive(:exit)

          subject
        end
      end

      context "with multiple behaviors (Definition order is important)" do
        context "with raise and none" do
          let(:behaviors) { [raise_behavior, default_behavior] }

          it "raises error" do
            expect { subject }.to raise_error(GemEnforcer::ValidationError, /Enforcer expects the most recent version/)
          end

          it "logs once" do
            expect(GemEnforcer.logger).to receive(:error).once

             expect { subject }.to raise_error(GemEnforcer::ValidationError)
          end
        end

        context "with raise and exit" do
          let(:behaviors) { [raise_behavior, exit_behavior] }

          it "raises error" do
            expect { subject }.to raise_error(GemEnforcer::ValidationError, /Enforcer expects the most recent version/)
          end

          it "logs once" do
            expect(GemEnforcer.logger).to receive(:error).once

            expect { subject }.to raise_error(StandardError)
          end
        end

        context "with exit and none" do
          before { allow(Kernel).to receive(:exit).with(1).and_raise(SpecialExitTestCase, "How to catch a Kernel.exit") }
          let(:behaviors) { [exit_behavior, default_behavior] }

          it "exits" do
            expect(Kernel).to receive(:exit)

            expect { subject }.to raise_error(SpecialExitTestCase)
          end

          it "logs once" do
            expect(GemEnforcer.logger).to receive(:error).once

            expect { subject }.to raise_error(SpecialExitTestCase)
          end
        end

        context "with exit and raise" do
          let(:behaviors) { [exit_behavior, raise_behavior] }
          before { allow(Kernel).to receive(:exit).with(1).and_raise(SpecialExitTestCase, "How to catch a Kernel.exit") }

          it "exits" do
            expect(Kernel).to receive(:exit)

            expect { subject }.to raise_error(SpecialExitTestCase)
          end

          it "logs once" do
            expect(GemEnforcer.logger).to receive(:error).once

            expect { subject }.to raise_error(SpecialExitTestCase)
          end
        end

        context "with none and raise" do
          let(:behaviors) { [default_behavior, raise_behavior] }

          it "raises error" do
            expect { subject }.to raise_error(GemEnforcer::ValidationError, /Enforcer expects the most recent version/)
          end

          it "logs twice" do
            expect(GemEnforcer.logger).to receive(:error).twice

             expect { subject }.to raise_error(GemEnforcer::ValidationError)
          end
        end

        context "with none and exit" do
          before { allow(Kernel).to receive(:exit).with(1).and_raise(SpecialExitTestCase, "How to catch a Kernel.exit") }
          let(:behaviors) { [default_behavior, exit_behavior] }

          it "exits" do
            expect(Kernel).to receive(:exit)

            expect { subject }.to raise_error(SpecialExitTestCase)
          end

          it "logs twice" do
            expect(GemEnforcer.logger).to receive(:error).twice

            expect { subject }.to raise_error(SpecialExitTestCase)
          end
        end

        context "with none and none" do
        end
      end
    end

    context "when invalid config" do
      let(:version) { version_list.sample }

      it do
        expect { run_validation }.to raise_error(GemEnforcer::Error, /Unable to run validation/)
      end
    end

    context "with server" do
      before do
        allow(GemEnforcer::Setup::Helper::Retrieval).to receive(:new).and_return(retrieval)
        allow(instance).to receive(:current_version).and_return(version)
      end

      let(:git) { nil }

      context "when valid" do
        let(:version) { version_list.max }

        it do
          is_expected.to eq(true)
        end

        context "when version is nil (Gem not loaded)" do
          let(:version) { nil }

          it do
            is_expected.to eq(true)
          end
        end
      end

      context "when invalid" do
        let(:version) { version_list.min }

        include_examples "with different behaviors"
      end
    end

    context "with git" do
      before do
        allow(GemEnforcer::Setup::Helper::Retrieval).to receive(:new).and_return(retrieval)
        allow(instance).to receive(:current_version).and_return(version)
      end

      let(:server) { nil }

      context "when valid" do
        let(:version) { version_list.max }

        it do
          is_expected.to eq(true)
        end

        context "when version is nil (Gem not loaded)" do
          let(:version) { nil }

          it do
            is_expected.to eq(true)
          end
        end
      end

      context "when invalid" do
        let(:version) { version_list.min }

        include_examples "with different behaviors"
      end
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
end
