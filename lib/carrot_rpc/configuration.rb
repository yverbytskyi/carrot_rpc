module CarrotRpc
  class Configuration
    attr_accessor :logger, :logfile, :loglevel, :daemonize, :pidfile, :runloop_sleep, :rails_path

    # logfile - set logger to a file. overrides rails logger.

    def initialize
      @logfile = nil
      @loglevel = Logger::DEBUG
      @logger = nil
      @daemonize = false
      @pidfile = nil
      @runloop_sleep = 0
      @rails_path = "../../"
    end
  end
end
