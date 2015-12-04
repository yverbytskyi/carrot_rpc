require 'spec_helper'
require 'carrot_rpc'
require 'carrot_rpc/cli'

describe CarrotRpc::CLI do
  subject { CarrotRpc::CLI }

  describe 'runloop sleep' do
    before(:each) { expect(CarrotRpc.configuration).to receive_message_chain('runloop_sleep=').with(10) }

    it 'sets the sleep value with long switch' do
      CarrotRpc::CLI.parse_options(["--runloop_sleep=10"])
    end
    it 'sets the sleep value with short switch' do
      CarrotRpc::CLI.parse_options(["-s", "10"])
    end
  end


  describe 'daemonize' do
    before(:each) { expect(CarrotRpc.configuration).to receive('daemonize=').with(true) }

    it 'sets daemonize value with long swtich' do
      CarrotRpc::CLI.parse_options(["--daemonize"])
    end

    it 'sets daemonize value with short switch' do
      CarrotRpc::CLI.parse_options(["-d"])
    end
  end

  it 'sets pid value with long swtich' do
    expect(CarrotRpc.configuration).to receive('pidfile=').with("snarg")
    CarrotRpc::CLI.parse_options(["--pid=snarg"])
  end

  it 'sets rails_path value with long swtich' do
    expect(CarrotRpc.configuration).to receive('rails_path=')
    CarrotRpc::CLI.parse_options(["--rails_path=stuff/snarg"])
  end


  it "sets the name of the logfile" do
    expect(CarrotRpc.configuration).to receive("logfile=")
    CarrotRpc::CLI.parse_options(["--logfile=rpc"])
  end
end
