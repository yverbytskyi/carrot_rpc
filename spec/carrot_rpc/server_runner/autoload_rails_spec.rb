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
