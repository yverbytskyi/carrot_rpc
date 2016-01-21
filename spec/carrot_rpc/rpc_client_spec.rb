require 'spec_helper'
require 'carrot_rpc'

describe CarrotRpc::RpcClient do
  subject { CarrotRpc::RpcClient.new }

  describe "#queue_name" do
    before :each do
      @channel = double("channel", close: true, queue: true, default_exchange: true)
      @bunny = double("bunny", close: true, create_channel: @channel)

      allow_any_instance_of(CarrotRpc::Configuration).to receive(:bunny) { @bunny }
    end

    it "has a queue name class method" do
      CarrotRpc::RpcClient.queue_name "foo"
      expect(CarrotRpc::RpcClient.queue_name).to eq "foo"
      # reset state
      CarrotRpc::RpcClient.queue_name nil
    end

    it "does not default queue name" do
      expect(@channel).to receive(:queue).with(nil, auto_delete: false)
      subject
    end
  end

  describe "#start" do
    after :each do
      server.channel.close
      subject.channel.close
    end

    subject do
      CarrotRpc::RpcClient.queue_name 'foo'
      CarrotRpc::RpcClient.new
    end

    let(:server) do
      CarrotRpc::RpcServer.queue_name 'foo'
      CarrotRpc::RpcServer.class_eval do
        def show(_params)
          { 'foo-baz' => { 'fizz-buzz' => 'baz', 'foo-bar' => 'biz',
                           'biz-baz' => { 'super-duper' => 'grovy' } } }
        end
      end

      CarrotRpc::RpcServer.new(block: false)
    end

    let(:result) do
      { 'foo_baz' => { 'fizz_buzz' => 'baz', 'foo_bar' => 'biz',
                       'biz_baz' => { 'super_duper' => 'grovy' } } }
    end

    it "parses the payload from json to hash and changes '-' to '_' in the keys" do
      subject.start
      server.start
      expect(subject.show({})).to eq result
    end
  end
end
