require 'spec_helper'
require 'carrot_rpc'

describe CarrotRpc::RpcServer do
  describe "#queue_name" do
    before :each do
      @channel = double("channel", close: true, queue: true, default_exchange: true)
      @bunny = double("bunny", close: true, create_channel: @channel)

      config = instance_double(CarrotRpc::Configuration, bunny: @bunny, logger: @logger)
      allow(CarrotRpc::Configuration).to receive(:new) { config }
    end

    it "has a queue name class method" do
      CarrotRpc::RpcServer.queue_name "foo"
      expect(CarrotRpc::RpcServer.get_queue_name).to eq "foo"
      # reset state
      CarrotRpc::RpcServer.queue_name nil
    end
  end
end
