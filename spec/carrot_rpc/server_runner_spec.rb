require "spec_helper"

RSpec.describe CarrotRpc::ServerRunner do
  subject(:server_runner) {
    CarrotRpc::ServerRunner.new(**args)
  }

  # lets

  let(:args) {
    {
      rails_path: File.expand_path("../../dummy", __FILE__)
    }
  }

  let(:logger) {
    instance_double(Logger, info: "", warn: "")
  }

  # Callbacks

  before :each do
    allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:logger).and_return(logger)

    @channel = double("channel", close: true)
    @bunny = double("bunny", close: true, create_channel: @channel)

    allow_any_instance_of(CarrotRpc::Configuration).to receive(:bunny) { @bunny }
  end

  describe "initialize" do
    let(:args) {
      {
        rails_path: File.expand_path("../../dummy", __FILE__)
      }
    }

    it "sets @servers to empty array" do
      subject
      expect(subject.instance_variable_get(:@servers)).to eq []
    end

    it "loads the rails app when passed" do
      expect(CarrotRpc::ServerRunner::AutoloadRails).to receive(:load_root).with(
        args[:rails_path],
        logger: logger
      )

      server_runner
    end

    it "calls a method to trap signal messages" do
      expect_any_instance_of(CarrotRpc::ServerRunner).to receive(:trap_signals)
      subject
    end

    context "passing params" do
      let(:args) do
        { rails_path: File.expand_path("../../dummy", __FILE__), pidfile: "foo", runloop_sleep: 5, daemonize: true }
      end

      it "sets instance vars to the params passed" do
        expect(subject.instance_variable_get(:@runloop_sleep)).to eq 5
        expect(subject.instance_variable_get(:@daemonize)).to eq true
      end

      it "sets pid.path to pidfile param" do
        expect(server_runner.pid.path).not_to eq nil
      end
    end
  end

  describe "#pid" do
    subject(:pid) {
      server_runner.pid
    }

    it "has path as nil by default" do
      expect(pid.path).to be_nil
    end

    context "with params" do
      let(:args) {
        {
          pidfile: "stuff",
          rails_path: File.expand_path("../../dummy", __FILE__)
        }
      }

      it "is path set by parameter" do
        expect(pid.path).to match("stuff")
      end
    end
  end

  describe "#runloop_sleep" do
    context "with valid params" do
      let(:args) { { rails_path: File.expand_path("../../dummy", __FILE__), runloop_sleep: 10 } }
      it "can be set" do
        expect(subject.instance_variable_get(:@runloop_sleep)).to eq 10
      end
    end
    it "has default" do
      expect(subject.instance_variable_get(:@runloop_sleep)).to eq 0
    end
  end

  describe "#daemonize?" do
    it "false by default" do
      expect(subject.daemonize?).to eq false
    end

    context "with true" do
      let(:args) { { rails_path: File.expand_path("../../dummy", __FILE__), daemonize: true } }
      it "true when set" do
        expect(subject.daemonize?).to eq true
      end
    end

    context "with false" do
      let(:args) { { rails_path: File.expand_path("../../dummy", __FILE__), daemonize: false } }

      it "false when set" do
        expect(subject.daemonize?).to eq false
      end
    end
  end

  describe "#run!" do
    before :each do
      # setting quit flag so that runloop stops immediately
      subject.shutdown
      allow(subject).to receive(:run_servers)
    end

    it "always calls essential methods" do
      expect(server_runner.pid).to receive(:check)
      expect(server_runner.pid).to receive(:ensure_written)
      expect(server_runner).to receive(:run_servers)
      expect(server_runner).to receive(:stop_servers)
      expect(server_runner).to_not receive(:daemonize)

      server_runner.run!
    end

    context "daemonize not set" do
      it "does not call daemonize" do
        expect(subject).to_not receive(:daemonize)
        subject.run!
      end
    end

    context "daemonize set" do
      let(:args) { { rails_path: File.expand_path("../../dummy", __FILE__), daemonize: true } }
      it "calls daemonize" do
        expect(subject).to receive(:daemonize)
        subject.run!
      end
    end
  end

  describe "#stop_servers" do
    before :each do
      @name = double("Name", name: "fake")
      @mock_server = double("RpcServer", queue: @name, channel: @channel, connection: @bunny)
      subject.instance_variable_set(:@servers, [@mock_server, @mock_server])
    end

    it "server receives shutdown methods" do
      expect(@channel).to receive("close").exactly(2).times
      expect(@bunny).to receive("close").exactly(1).times
      subject.stop_servers
    end
  end

  describe "#run_servers" do
    before :all do
      path = $LOAD_PATH.first
      $LOAD_PATH.unshift([path, "dummy", "app", "servers"].join("/"))
    end

    after :all do
      $LOAD_PATH.shift
    end

    it "loads the servers" do
      servers = subject.run_servers(dirs: %w(spec dummy app servers))
      expect(servers.first.class).to eq(FooServer)
    end
  end

  describe "#set_logger" do
    let(:args) { { rails_path: nil } }
    before :each do
      CarrotRpc.configuration.autoload_rails = false
    end

    after :each do
      CarrotRpc.configuration.autoload_rails = true
    end

    context "when config is set to use a logfile" do
      it "a logger is created" do
        CarrotRpc::CLI.parse_options(["--logfile=../rpc.log"])
        logger = instance_double(Logger, level: 1)
        expect(logger).to receive(:level=)
        expect(Logger).to receive(:new).with(CarrotRpc.configuration.logfile) { logger }
        subject.send(:set_logger)
      end

      it "sets a logger for the config" do
        expect(CarrotRpc.configuration).to receive(:logger=)
        subject.send(:set_logger)
      end
    end
  end
end
