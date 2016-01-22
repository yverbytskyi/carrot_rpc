require "spec_helper"
require "carrot_rpc"

RSpec.describe CarrotRpc::RpcServer do
  describe "#queue_name" do
    let(:server_class) {
      Class.new(CarrotRpc::RpcServer)
    }

    it "is readable by queue_name/0" do
      server_class.queue_name "foo"
      expect(server_class.queue_name).to eq "foo"
    end
  end

  describe "#start" do
    # Methods

    def delete_queue
      channel = CarrotRpc.configuration.bunny.create_channel
      queue = channel.queue("foo")
      queue.delete
      channel.close
    end

    # lets

    let(:client_class) {
      Class.new(CarrotRpc::RpcClient) do
        queue_name "foo"
      end
    }

    let(:client) do
      client_class.new
    end

    let(:server_class) {
      Class.new(CarrotRpc::RpcServer) do
        queue_name "foo"

        # Instance Methods

        def create(params)
          params
        end
      end
    }

    let(:server) {
      server_class.new(block: false)
    }

    # Callbacks

    before(:each) do
      # Delete queue if another test did not clean up properly, such as due to interrupt
      delete_queue

      client.start
    end

    after(:each) do
      client.channel.close
      server.channel.close

      # Clean up properly
      delete_queue
    end

    context "with server started" do
      # lets

      let(:payload) do
        {
          "foo-baz" => {
            "biz-baz" => {
              "super-duper" => "grovy"
            },
            "fizz-buzz" => "baz",
            "foo-bar" => "biz"
          }
        }
      end

      let(:result) do
        {
          "foo_baz" => {
            "biz_baz" => {
              "super_duper" => "grovy"
            },
            "fizz_buzz" => "baz",
            "foo_bar" => "biz"
          }
        }
      end

      # Callbacks

      before(:each) do
        server.start
      end

      it "parses the payload from json to hash and changes '-' to '_' in the keys" do
        expect(client.create(payload)).to eq result
      end
    end
  end
end
