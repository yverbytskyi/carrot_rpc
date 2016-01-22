require "spec_helper"

RSpec.describe CarrotRpc::ServerRunner::Pid do
  subject(:pid) {
    described_class.new(path: path, logger: logger)
  }

  let(:logger) {
    instance_double(Logger)
  }

  context "#check" do
    subject(:check) {
      pid.check
    }

    # lets

    let(:path) {
      "/dev/null"
    }

    let(:logger) {
      instance_double(Logger)
    }

    it "exits when there's an running pid and logs error" do
      allow(described_class).to receive(:path_status).with(path).and_return(:running)
      expect(logger).to receive(:warn).with("A server is already running. Check #{path}")

      expect {
        check
      }.to terminate.with_code 1
    end

    it "exits when there's a not_owned pid and logs error" do
      allow(described_class).to receive(:path_status).with(path).and_return(:not_owned)
      expect(logger).to receive(:warn).with("A server is already running. Check #{path}")

      expect {
        check
      }.to terminate.with_code 1
    end

    it "removes the path when process is dead" do
      allow(described_class).to receive(:path_status).with(path).and_return(:dead)
      expect(pid).to receive(:delete)

      check
    end
  end

  context ".path_status" do
    subject(:path_status) {
      described_class.path_status(path)
    }

    # lets

    let(:path) {
      File.expand_path("../../../dummy/tmp/pids/#{pid_name}", __FILE__)
    }

    context "path doesn't exist" do
      let(:pid_name) {
        "foo.pid"
      }

      it "returns :exited" do
        expect(path_status).to eq :exited
      end
    end

    context "path exists but is terminated" do
      let(:pid_name) {
        "dead.pid"
      }

      it "returns :dead" do
        expect(path_status).to eq :dead
      end
    end

    context "path exists and is running" do
      # lets

      let(:pid_name) {
        "running.pid"
      }

      # Callbacks

      before(:each) do
        pid.ensure_written
      end

      after(:each) do
        File.delete path
      end

      it "returns :running" do
        expect(path_status).to eq :running
      end
    end
  end

  context "#write" do
    subject(:write) {
      pid.write
    }

    # lets

    let(:path) {
      File.expand_path("../../../dummy/tmp/pids/#{pid_name}", __FILE__)
    }

    let(:pid_name) {
      "running.pid"
    }

    # Callbacks

    after(:each) do
      File.delete path
    end

    it "creates a pidfile for a running process" do
      expect {
        write
      }.to change {
        File.exist? path
      }.to(true)

      expect(File.read(path).to_i).not_to eq(0)
    end
  end
end
