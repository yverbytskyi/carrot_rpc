require 'spec_helper'
require 'carrot_rpc'

describe CarrotRpc::RpcServer do
  subject { CarrotRpc::RpcServer.new }

  describe "#queue_name" do
    before :each do
      @channel = double("channel", close: true, queue: true, default_exchange: true)
      @bunny = double("bunny", close: true, create_channel: @channel)

      allow_any_instance_of(CarrotRpc::Configuration).to receive(:bunny) { @bunny }
    end

    it "has a queue name class method" do
      CarrotRpc::RpcServer.queue_name "foo"
      expect(CarrotRpc::RpcServer.get_queue_name).to eq "foo"
      # reset state
      CarrotRpc::RpcServer.queue_name nil
    end

    it "does not default queue name" do
      expect(@channel).to receive(:queue).with(nil)
      subject
    end
  end
end
