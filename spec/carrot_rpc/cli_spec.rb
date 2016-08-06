require "spec_helper"
require "carrot_rpc"
require "carrot_rpc/cli"

RSpec.describe CarrotRpc::CLI do
  subject { CarrotRpc::CLI }

  describe "daemonize" do
    before(:each) do
      expect(CarrotRpc.configuration).to receive("daemonize=").with(true)
    end

    it "sets daemonize value with long swtich" do
      CarrotRpc::CLI.parse_options(["--daemonize"])
    end

    it "sets daemonize value with short switch" do
      CarrotRpc::CLI.parse_options(["-d"])
    end
  end

  it "sets pid value with long swtich" do
    expect(CarrotRpc.configuration).to receive("pidfile=").with("snarg")
    CarrotRpc::CLI.parse_options(["--pid=snarg"])
  end

  it "sets autoload_rails value with long swtich" do
    expect(CarrotRpc.configuration).to receive("autoload_rails=")
    CarrotRpc::CLI.parse_options(["--autoload_rails=false"])
  end

  it "sets the name of the logfile" do
    expect(CarrotRpc.configuration).to receive("logfile=")
    CarrotRpc::CLI.parse_options(["--logfile=rpc"])
  end

  it "initializes a Bunny object from the connection string" do
    expect(CarrotRpc.configuration).to receive("bunny=")
    expect(Bunny).to receive(:new).with "amqp://guest:guest@rabbitmq:5672"
    CarrotRpc::CLI.parse_options(["--rabbitmq_url=amqp://guest:guest@rabbitmq:5672"])
  end

  it "set server_test_mode with long switch" do
    expect(CarrotRpc.configuration).to receive("server_test_mode=").with(true)
    CarrotRpc::CLI.parse_options(["--server_test_mode"])
  end
end
