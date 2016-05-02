# Global configuration for {CarrotRpc}.  Access with {CarrotRpc.configuration}.
class CarrotRpc::Configuration
  attr_accessor :logger, :logfile, :loglevel, :daemonize, :pidfile, :runloop_sleep, :autoload_rails, :bunny,
                :before_request, :rpc_client_timeout, :rpc_client_response_key_format, :rpc_client_request_key_format

  # logfile - set logger to a file. overrides rails logger.

  def initialize # rubocop:disable Metrics/MethodLength
    @logfile = nil
    @loglevel = Logger::DEBUG
    @logger = nil
    @daemonize = false
    @pidfile = nil
    @runloop_sleep = 0
    @autoload_rails = true
    @bunny = nil
    @before_request = nil
    @rpc_client_timeout = 5
    @rpc_client_response_key_format = :none
    @rpc_client_request_key_format = :none
  end # rubocop:enable Metrics/MethodLength
end
