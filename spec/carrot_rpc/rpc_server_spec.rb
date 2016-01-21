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
      expect(CarrotRpc::RpcServer.queue_name).to eq "foo"
      # reset state
      CarrotRpc::RpcServer.queue_name nil
    end
  end

  describe "#start" do
    after :each do
      client.channel.close
      subject.channel.close
    end

    subject do
      CarrotRpc::RpcServer.queue_name 'foo'
      CarrotRpc::RpcServer.class_eval do
        def create(params)
          params
        end
      end

      CarrotRpc::RpcServer.new(block: false)
    end

    let(:client) do
      CarrotRpc::RpcClient.queue_name 'foo'
      CarrotRpc::RpcClient.new
    end

    let(:payload) do
      { 'foo-baz' => { 'fizz-buzz' => 'baz', 'foo-bar' => 'biz',
                       'biz-baz' => { 'super-duper' => 'grovy' } } }
    end
    let(:result) do
      { 'foo_baz' => { 'fizz_buzz' => 'baz', 'foo_bar' => 'biz',
                       'biz_baz' => { 'super_duper' => 'grovy' } } }
    end

    it "parses the payload from json to hash and changes '-' to '_' in the keys" do
      client.start
      subject.start
      expect(client.create(payload)).to eq result
    end
  end
end
