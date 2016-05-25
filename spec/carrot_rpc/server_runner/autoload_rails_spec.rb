require "spec_helper"

RSpec.describe CarrotRpc::ServerRunner::AutoloadRails do
  context ".load_root" do
    subject(:load_root) {
      described_class.load_root(
        root,
        logger: logger
      )
    }

    let(:logger) {
      instance_double(Logger, info: nil)
    }

    context "with valid root" do
      let(:root) {
        File.expand_path("../../../dummy", __FILE__)
      }

      it "returns true" do
        expect(load_root).to eq true
      end

      it "sets rails / rack env to development by default" do
        load_root
        expect(ENV["RAILS_ENV"]).to eq "development"
        expect(ENV["RACK_ENV"]).to eq "development"
      end

      context "with server_test_mode enabled" do
        before :each do
          CarrotRpc.configuration.server_test_mode = true
          load_root
        end

        after :each do
          CarrotRpc.configuration.server_test_mode = false
        end

        it "sets rails / rack env to test" do
          expect(ENV["RAILS_ENV"]).to eq "test"
          expect(ENV["RACK_ENV"]).to eq "test"
        end
      end
    end

    context "without valid root" do
      let(:root) {
        File.expand_path("../../foo", __FILE__)
      }

      it "raises LoadError" do
        expect {
          load_root
        }.to raise_error(LoadError)
      end
    end
  end
end
