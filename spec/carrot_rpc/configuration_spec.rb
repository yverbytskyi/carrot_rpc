require "spec_helper"
require "carrot_rpc/configuration"

describe CarrotRpc::Configuration do
  subject { CarrotRpc::Configuration.new }

  it 'defaults daemonize' do
    expect(subject.daemonize).to eq false
  end

  it 'defaults pidfile' do
    expect(subject.pidfile).to eq nil
  end

  it 'defaults runloop sleep' do
    expect(subject.runloop_sleep).to eq 0
  end

  it 'defaults rails path' do
    expect(subject.rails_path).to eq "../../"
  end

  it "defaults log file" do
    expect(subject.logfile).to eq nil
  end
end
