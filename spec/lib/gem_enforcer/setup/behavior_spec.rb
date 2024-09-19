# frozen_string_literal: true

RSpec.describe GemEnforcer::Setup::Behavior do
  let(:instance) { described_class.new(gem_name:, index:, **params) }
  let(:gem_name) { "faraday" }
  let(:index) { rand(0..50) }
  let(:params) { { on_failure:, version_enforce: } }
  let(:on_failure) { {} }
  let(:version_enforce) { { insync: true } }
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

  describe "#initialize" do
    context "with string keys" do
      let(:params) { { "one" => 1, "two" => 2, "three" => 3 } }

      it do
        expect(instance.gem_name).to eq(gem_name)
      end

      it do
        expect(instance.params[:one]).to eq(1)
      end

      it do
        expect(instance.params[:two]).to eq(2)
      end

      it do
        expect(instance.params[:three]).to eq(3)
      end
    end

    context "when hash keys" do
      let(:params) { { one: 1, two: 2, three: 3 } }

      it do
        expect(instance.gem_name).to eq(gem_name)
      end

      it do
        expect(instance.params[:one]).to eq(1)
      end

      it do
        expect(instance.params[:two]).to eq(2)
      end

      it do
        expect(instance.params[:three]).to eq(3)
      end
    end
  end

  describe "#valid_config?" do
    subject(:valid_config) { instance.valid_config? }

    context "when valid" do
      it do
        is_expected.to eq(true)
      end

      it do
        valid_config

        expect(instance.error_status).to be_nil
      end
    end

    context "when invalid" do
      context "with invalid version_enforce" do
        let(:version_enforce) { { insync: false } }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(1)
          expect(instance.error_status.first).to include("version_enforce.insync")
        end
      end

      context "with invalid on_failure" do
        let(:on_failure) { { behavior: :invalid } }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(1)
          expect(instance.error_status.first).to include("on_failure.behavior")
        end
      end

      context "with invalid on_failure and version_enforce" do
        let(:version_enforce) { { insync: false } }
        let(:on_failure) { { behavior: :invalid } }

        it do
          is_expected.to eq(false)
        end

        it "correct errors" do
          valid_config

          expect(instance.error_status.length).to eq(2)
          expect(instance.error_status[0]).to include("version_enforce.insync")
          expect(instance.error_status[1]).to include("on_failure.behavior")
        end
      end
    end
  end

  describe "#run_behavior!" do
    subject(:run_behavior) { instance.run_behavior!(version_list:, version:) }

    let(:version) { version_list.sample }

    context "with invalid config" do
      let(:version_enforce) { { insync: false } }

      it do
        expect { run_behavior }.to raise_error(GemEnforcer::ConfigError, "Attempted to run validations with invalid Version Configurations")
      end
    end

    context "when version is nil" do
      let(:version) { nil }

      it do
        is_expected.to eq(true)
      end

      it do
        expect(instance.version_enforcer).to_not receive(:valid_gem_versions?)

        run_behavior
      end
    end

    context "when version_enforce is invalid" do
      let(:version) { version_list.sort[-2] }

      it do
        is_expected.to eq(false)
      end
    end

    context "when version_enforce is valid" do
      let(:version) { version_list.sort[-1] }

      it do
        is_expected.to eq(true)
      end
    end
  end
end
