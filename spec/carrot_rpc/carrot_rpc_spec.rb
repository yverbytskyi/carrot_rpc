require "spec_helper"
require "carrot_rpc"

RSpec.describe CarrotRpc do
  it "has a configuration object" do
    expect(CarrotRpc.configuration).to be_an_instance_of(CarrotRpc::Configuration)
  end

  it "can use #configure to pass a block" do
    CarrotRpc.configure do |config|
      config.runloop_sleep = 2000
    end
    expect(CarrotRpc.configuration.runloop_sleep).to eq 2000
  end
end
