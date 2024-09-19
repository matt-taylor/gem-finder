# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Helper::OnFailure do
  let(:instance) { described_class.new(gem_name:, on_failure:) }
  let(:gem_name) { "faraday" }
  let(:on_failure) { {} }
  before do
    # nullify log output
    GemEnforcer.configuration.logger = Logger.new("/dev/null")
  end

  describe ".initialize" do
    context "with string keys" do
      let(:on_failure) { { "one" => 1, "two" => 2, "three" => 3 } }

      it do
        expect(instance.gem_name).to eq(gem_name)
      end

      it do
        expect(instance.on_failure[:one]).to eq(1)
      end

      it do
        expect(instance.on_failure[:two]).to eq(2)
      end

      it do
        expect(instance.on_failure[:three]).to eq(3)
      end
    end

    context "when emtpy" do
      it do
        expect(instance.gem_name).to eq(gem_name)
      end

      it do
        expect(instance.on_failure).to be_empty
      end
    end

    context "when hash keys" do
      let(:on_failure) { { one: 1, two: 2, three: 3 } }

      it do
        expect(instance.gem_name).to eq(gem_name)
      end

      it do
        expect(instance.on_failure[:one]).to eq(1)
      end

      it do
        expect(instance.on_failure[:two]).to eq(2)
      end

      it do
        expect(instance.on_failure[:three]).to eq(3)
      end
    end
  end

  describe "#valid_config?" do
    subject(:valid_config) { instance.valid_config? }

    context "when invalid" do
      context "when not a hash" do
        let(:on_failure) { [] }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("Expected to contain a Hash")
        end
      end

      context "with invalid keys" do
        let(:on_failure) { { invalid_key: "foo", behavior: :exit } }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("Contained unexpected keys")
        end
      end

      context "with invalid behavior option" do
        let(:on_failure) { { behavior: :NOPE } }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.errors.length).to eq(1)
          expect(instance.errors.first).to include("Value must be one of #{described_class::ALLOWED_FAILURE_BEHAVIOR}")
        end
      end
    end

    context "when valid" do
      context "with log_level" do
        let(:on_failure) { { log_level: :value_does_not_matter } }

        it do
          is_expected.to eq(true)
        end
      end

      context "with behavior" do
        let(:on_failure) { { behavior: described_class::ALLOWED_FAILURE_BEHAVIOR.sample } }

        it do
          is_expected.to eq(true)
        end
      end

      context "with log_level and behavior" do
        let(:on_failure) { { log_level: :value_does_not_matter, behavior: described_class::ALLOWED_FAILURE_BEHAVIOR.sample } }

        it do
          is_expected.to eq(true)
        end
      end
    end
  end

  describe "#run_on_failure!" do
    subject(:run_on_failure) { instance.run_on_failure!(message:) }

    let(:message) { "This is my failure message" }
    context "with invalid config" do
      let(:on_failure) { { invalid_key: 1 } }

      it do
        expect { run_on_failure }.to raise_error(GemEnforcer::ConfigError, /Attempted to run on_failure with an invalid config./)
      end
    end

    context "with raise" do
      let(:on_failure) { { behavior: :raise } }

      it do
        expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(message)

        expect { run_on_failure }.to raise_error(GemEnforcer::ValidationError)
      end

      it do
        expect { run_on_failure }.to raise_error(GemEnforcer::ValidationError, message)
      end

      context "with custom message" do
        let(:custom_message) { "this message takes precedence" }
        let(:on_failure) { super().merge(message: custom_message) }

        it do
          expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(custom_message)

          expect { run_on_failure }.to raise_error(GemEnforcer::ValidationError)
        end

        it do
          expect { run_on_failure }.to raise_error(GemEnforcer::ValidationError, custom_message)
        end
      end

      context "with log_level" do
        let(:on_failure) { super().merge(log_level: :info) }

        it do
          expect(GemEnforcer.logger).to receive(:info).with(message)

          expect { run_on_failure }.to raise_error(GemEnforcer::ValidationError)
        end
      end
    end

    context "with exit" do
      let(:on_failure) { { behavior: :exit } }
      before { allow(Kernel).to receive(:exit) }

      it do
        expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(message)

        run_on_failure
      end

      it do
        expect(Kernel).to receive(:exit).with(1) #stub this

        run_on_failure
      end

      context "with custom message" do
        let(:custom_message) { "this message takes precedence" }
        let(:on_failure) { super().merge(message: custom_message) }

        it do
          expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(custom_message)

          run_on_failure
        end

        it do
          expect(Kernel).to receive(:exit).with(1) #stub this

          run_on_failure
        end
      end

      context "with log_level" do
        let(:on_failure) { super().merge(log_level: :info) }

        it do
          expect(GemEnforcer.logger).to receive(:info).with(message)

          run_on_failure
        end
      end
    end

    context "with none (Default Behavior)" do
      let(:on_failure) { { behavior: :none } }

      it do
        expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(message)

        run_on_failure
      end

      it do
        is_expected.to eq(true)
      end

      it "does not raise nor exit" do
        expect(Kernel).to_not receive(:exit)

        expect { run_on_failure }.to_not raise_error
      end

      context "with custom message" do
        let(:custom_message) { "this message takes precedence" }
        let(:on_failure) { super().merge(message: custom_message) }

        it do
          expect(GemEnforcer.logger).to receive(described_class::DEFAULT_LOG_LEVEL).with(custom_message)

          run_on_failure
        end

        it do
          is_expected.to eq(true)
        end

        it "does not raise nor exit" do
          expect(Kernel).to_not receive(:exit)

          expect { run_on_failure }.to_not raise_error
        end
      end

      context "with log_level" do
        let(:on_failure) { super().merge(log_level: :info) }

        it do
          expect(GemEnforcer.logger).to receive(:info).with(message)

          run_on_failure
        end
      end
    end
  end
end
