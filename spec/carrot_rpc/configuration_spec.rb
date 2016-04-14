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

  it "defaults runloop sleep" do
    expect(subject.runloop_sleep).to eq 0
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
end
