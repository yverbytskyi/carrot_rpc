class CarrotRpc::Configuration
  attr_accessor :logger, :logfile, :loglevel, :daemonize, :pidfile, :runloop_sleep, :autoload_rails, :bunny

  # logfile - set logger to a file. overrides rails logger.

  def initialize
    @logfile = nil
    @loglevel = Logger::DEBUG
    @logger = nil
    @daemonize = false
    @pidfile = nil
    @runloop_sleep = 0
    @autoload_rails = true
    @bunny = nil
  end
end
