# Global configuration for {CarrotRpc}.  Access with {CarrotRpc.configuration}.
class CarrotRpc::Configuration
  attr_accessor :logger, :logfile, :loglevel, :daemonize, :pidfile, :autoload_rails, :bunny,
                :before_request, :rpc_client_timeout, :rpc_client_response_key_format, :rpc_client_request_key_format,
                :server_test_mode, :client_test_mode, :thread_request_variable

  # logfile - set logger to a file. overrides rails logger.

  def initialize # rubocop:disable Metrics/MethodLength
    @logfile = nil
    @loglevel = Logger::DEBUG
    @logger = nil
    @daemonize = false
    @pidfile = nil
    @autoload_rails = true
    @bunny = nil
    @before_request = nil
    @rpc_client_timeout = 5
    @rpc_client_response_key_format = :none
    @rpc_client_request_key_format = :none
    @client_test_mode = false
    @server_test_mode = false
    @thread_request_variable = nil
  end # rubocop:enable Metrics/MethodLength
end
