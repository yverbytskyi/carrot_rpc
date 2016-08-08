require "spec_helper"
require "carrot_rpc/configuration"

RSpec.describe CarrotRpc::Configuration do
  subject { CarrotRpc::Configuration.new }

  it "defaults daemonize" do
    expect(subject.daemonize).to eq false
  end

  it "defaults pidfile" do
    expect(subject.pidfile).to eq nil
  end

  it "defaults to load rails" do
    expect(subject.autoload_rails).to eq true
  end

  it "defaults log file" do
    expect(subject.logfile).to eq nil
  end

  it "defaults bunny" do
    expect(subject.bunny).to eq nil
  end

  it "defaults a before_request Proc" do
    expect(subject.before_request).to eq nil
  end

  it "defaults to rpc_client_timeout to 5 seconds" do
    expect(subject.rpc_client_timeout).to eq 5
  end

  it "defaults rpc_client_response_key_format" do
    expect(subject.rpc_client_response_key_format).to eq :none
  end

  it "defaults rpc_client_request_key_format" do
    expect(subject.rpc_client_request_key_format).to eq :none
  end

  it "defaults client_test_mode to false" do
    expect(subject.client_test_mode).to eq false
  end

  it "defaults server_test_mode to false" do
    expect(subject.server_test_mode).to eq false
  end
end
