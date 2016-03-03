require "spec_helper"
require "active_support/logger"
require "active_support/tagged_logging"

RSpec.describe CarrotRpc::TaggedLog do
  let(:log) do
    Logger.new(STDOUT)
  end
  let(:tagged_log) do
    ActiveSupport::TaggedLogging.new(log)
  end

  subject { described_class.new(logger: tagged_log, tags: ["Carrot Foo"]) }

  it "logs a string" do
    expect(log).to receive(:send).with(:info, "Foo!")
    subject.info "Foo!"
  end

  it "logs a block" do
    expect(log).to receive(:send).with(:info, "Bar!")
    subject.info { "Bar!" }
  end
end
