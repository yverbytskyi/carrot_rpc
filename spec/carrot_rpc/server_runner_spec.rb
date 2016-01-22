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

  # Callbacks

  before(:each) do
    # prevents configuration logger from actually being set
    allow(CarrotRpc.configuration).to receive(:logger=)
  end

  describe "initialize" do
    let(:args) {
      {
        rails_path: File.expand_path("../../dummy", __FILE__)
      }
    }

    it "sets @servers to empty array" do
      server_runner

      expect(server_runner.servers).to eq []
    end

    it "loads the rails app when passed" do
      expect(CarrotRpc::ServerRunner::AutoloadRails).to receive(:load_root).with(
        args[:rails_path],
        hash_including(logger: anything)
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
      server_runner.shutdown("QUIT")
      allow(server_runner).to receive(:run_servers)
    end

    after(:each) do
      # restore connection closed by CarrotRpc::ServerRunner#stop_servers
      bunny = Bunny.new
      bunny.start

      CarrotRpc.configuration.bunny = bunny
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
    subject(:stop_servers) {
      server_runner.stop_servers
    }

    let(:servers) {
      Array.new(2) { |i|
        klass = Class.new(CarrotRpc::RpcServer)
        klass.queue_name("queue#{i}")

        klass.new
      }
    }

    # Callbacks

    before :each do
      server_runner.instance_variable_set(:@servers, servers)
    end

    after(:each) do
      # restore connection closed by CarrotRpc::ServerRunner#stop_servers
      bunny = Bunny.new
      bunny.start

      CarrotRpc.configuration.bunny = bunny
    end

    it "server receives shutdown methods" do
      servers.each do |server|
        expect(server.channel).to receive(:close).and_call_original
      end

      expect(CarrotRpc.configuration.bunny).to receive(:close)

      stop_servers
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
    subject(:set_logger) {
      # calls #set_logger because #logger calls #set_logger and #logger is called in #initialize
      server_runner
    }

    it "calls CarrotRpc::ServerRunner::Logger.configured" do
      expect(CarrotRpc::ServerRunner::Logger).to receive(:configured).and_call_original

      set_logger
    end

    it "sets CarrotRpc.configuration.logger" do
      expect(CarrotRpc.configuration).to receive(:logger=)

      server_runner
    end
  end
end
