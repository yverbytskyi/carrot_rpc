require "spec_helper"
require "carrot_rpc"

RSpec.describe CarrotRpc do
  it "has a configuration object" do
    expect(CarrotRpc.configuration).to be_an_instance_of(CarrotRpc::Configuration)
  end

  it "can use #configure to pass a block" do
    CarrotRpc.configure do |config|
      config.loglevel = Logger::ERROR
    end
    expect(CarrotRpc.configuration.loglevel).to eq Logger::ERROR
  end
end
