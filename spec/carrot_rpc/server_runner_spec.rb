require 'spec_helper'
require 'carrot_rpc/server_runner'

describe CarrotRpc::ServerRunner do
  let(:args) { {} }
  subject{ CarrotRpc::ServerRunner.new(**args) }

  before :each do
    @logger = instance_double(Logger, info: "", warn: "")
    allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:logger) { @logger }

    bunny = double("bunny")
    @channel = double("channel", close: true)
    @connection = double("connection", close: true, create_channel: @channel)

    allow(bunny).to receive("connection") { @connection }
    allow_any_instance_of(CarrotRpc::Configuration).to receive(:bunny) { bunny }
  end

  describe "initialize" do
    let(:args) { { rails_path: File.expand_path("../../dummy", __FILE__) } }

    it "sets @servers to empty array" do
      subject
      expect(subject.instance_variable_get(:@servers)).to eq []
    end

    it "loads the rails app when passed" do
      expect_any_instance_of(CarrotRpc::ServerRunner).to receive(:load_rails_app).with(args[:rails_path])
      subject
    end

    it "calls a method to trap signal messages" do
      expect_any_instance_of(CarrotRpc::ServerRunner).to receive(:trap_signals)
      subject
    end

    context "passing params" do
      let(:args) { { pidfile: 'foo', runloop_sleep: 5, daemonize: true } }

      it "sets instance vars to the params passed" do
        expect(subject.instance_variable_get(:@pidfile)).to_not eq nil
        expect(subject.instance_variable_get(:@runloop_sleep)).to eq 5
        expect(subject.instance_variable_get(:@daemonize)).to eq true
      end
    end
  end

  describe "#check_pid" do
    before :each do
      allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:pidfile?) { true }
    end

    it "exits when there's an running pid and logs error" do
      allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:pid_status) { :running }
      expect(@logger).to receive(:warn)
      expect{ subject.check_pid }.to terminate.with_code 1
    end

    it "exits when there's a not_owned pid and logs error" do
      allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:pid_status) { :not_owned }
      expect(@logger).to receive(:warn)
      expect{ subject.check_pid }.to terminate.with_code 1
    end

    it "removes the file when process is dead" do
      allow_any_instance_of(CarrotRpc::ServerRunner).to receive(:pid_status) { :dead }
      file = double(File, delete: "")
      allow(File).to receive(:delete)
      expect(File).to receive(:delete)
      subject.check_pid
    end
  end

  describe "#pid_status" do
    let(:pid_name) { "foo.pid" }
    let(:path) { File.expand_path("../../dummy/tmp/pids/#{pid_name}", __FILE__)}

    context "file doesn't exist" do
      it "returns exited" do
        expect(subject.pid_status(path)).to eq :exited
      end
    end

    context "file exists but is terminated" do
      let(:pid_name) { "dead.pid" }
      it "returns dead" do
        expect(subject.pid_status(path)).to eq :dead
      end
    end

    context "file exists and is running" do
      let(:pid_name) { "running.pid" }
      it "returns running" do
        subject.instance_variable_set(:@pidfile, path)
        subject.write_pid
        expect(subject.pid_status(path)).to eq :running
        File.delete(path)
      end
    end
  end

  describe "#write_pid" do
    let(:pid_name) { "running.pid" }
    let(:path) { File.expand_path("../../dummy/tmp/pids/#{pid_name}", __FILE__)}

    it "creates a pidfile for a running process" do
      subject.instance_variable_set(:@pidfile, path)
      expect(subject.write_pid).to be_a Proc
      File.delete(path)
    end
  end

  describe "#pidfile" do
    it "nil by default" do
      expect(subject.pidfile).to eq nil
    end

    context "with params" do
      let(:args) { { pidfile: "stuff" } }

      it "is set by parameter" do
        expect(subject.pidfile).to match("stuff")
      end
    end
  end

  describe "#runloop_sleep" do
    context "with valid params" do
      let(:args) { { runloop_sleep: 10 } }
      it "can be set" do
        expect(subject.instance_variable_get(:@runloop_sleep)).to eq 10
      end
    end
    it "has default" do
      expect(subject.instance_variable_get(:@runloop_sleep)).to eq 0
    end
  end

  describe "#load_rails_app" do
    it "returns true if the rails app can be found" do
      path = File.expand_path("../../dummy", __FILE__)
      expect(subject.load_rails_app(path)).to eq true
    end

    it "rails if the rails app can not be found" do
      path = File.expand_path("../foo", __FILE__)
      expect{subject.load_rails_app(path)}.to raise_error LoadError
    end
  end

  describe "#daemonize?" do
    it "false by default" do
      expect(subject.daemonize?).to eq false
    end

    context "with true" do
      let(:args){ { daemonize: true } }
      it "true when set" do
        expect(subject.daemonize?).to eq true
      end
    end

    context "with false" do
      let(:args){ { daemonize: false } }

      it "false when set" do
        expect(subject.daemonize?).to eq false
      end
    end
  end

  describe "#run!" do
    before :each do
      # setting quit flag so that runloop stops immediately
      subject.shutdown
    end

    it "always calls essential methods" do
      expect(subject).to receive(:check_pid)
      expect(subject).to receive(:write_pid)
      expect(subject).to receive(:run_servers)
      expect(subject).to receive(:stop_servers)
      expect(subject).to_not receive(:daemonize)
      subject.run!
    end

    context "daemonize not set" do
      it "does not call daemonize" do
        expect(subject).to_not receive(:daemonize)
        subject.run!
      end
    end

    context "daemonize set" do
      let(:args) { { daemonize: true } }
      it "calls daemonize" do
        expect(subject).to receive(:daemonize)
        subject.run!
      end
    end
  end

  describe "#stop_servers" do
    before :each do
      @name = double("Name", name: "fake")
      @mock_server = double("RpcServer", queue: @name, channel: @channel, connection: @connection)
      subject.instance_variable_set(:@servers, [@mock_server, @mock_server])
    end

    it "server receives shutdown methods" do
      expect(@channel).to receive("close").exactly(2).times
      expect(@connection).to receive("close").exactly(1).times
      subject.stop_servers
    end
  end

  describe "#run_servers" do
    it "loads the servers" do
      servers = subject.run_servers(dirs: %w(spec dummy app servers), path: '../../')
      expect(servers.first.class).to eq(FooServer)
    end
  end
end
