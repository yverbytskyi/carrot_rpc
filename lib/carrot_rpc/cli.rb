# Command-line interface for {CarrotRpc}
module CarrotRpc::CLI
  def self.add_common_options(option_parser)
    option_parser.separator ""

    option_parser.separator "Common options:"
    option_parser.on("-h", "--help") do
      puts option_parser.to_s
      exit
    end

    option_parser.on("-v", "--version") do
      puts CarrotRpc::VERSION
      exit
    end
  end

  # There are just too many options in the Process options category and they can't really be broken down more
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

  # Add "Process options" to `option_parser`.
  #
  # @param option_parser [OptionParser]
  # @return [OptionParser]
  def self.add_process_options(option_parser)
    option_parser.separator ""

    option_parser.separator "Process options:"
    option_parser.on("-d", "--daemonize", "run daemonized in the background (default: false)") do
      CarrotRpc.configuration.daemonize = true
    end

    option_parser.on(" ", "--pidfile PIDFILE", "the pid filename") do |value|
      CarrotRpc.configuration.pidfile = value
    end

    option_parser.on("-s", "--runloop_sleep VALUE", Float, "Configurable sleep time in the runloop") do |value|
      CarrotRpc.configuration.runloop_sleep = value
    end

    stm_msg = "runs servers with '_test' appended to queue names." \
              "Set Rails Rack env vars to 'test' when used in conjunction with '--autoload_rails'"
    option_parser.on(" ", "--server_test_mode", stm_msg) do
      CarrotRpc.configuration.server_test_mode = true
    end

    option_parser.on(
      " ",
      "--autoload_rails value",
      "loads rails env by default. Uses Rails Logger by default."
    ) do |value|
      pv = value == "false" ? false : true
      CarrotRpc.configuration.autoload_rails = pv
    end

    option_parser.on(" ", "--logfile VALUE", "relative path and name for Log file. Overrides Rails logger.") do |value|
      CarrotRpc.configuration.logfile = File.expand_path("../../#{value}", __FILE__)
    end

    option_parser.on(
      " ",
      "--loglevel VALUE",
      "levels of loggin: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN"
    ) do |value|
      CarrotRpc.configuration.loglevel = Logger.const_get(value) || 0
    end

    # Optional. Defaults to using the ENV['RABBITMQ_URL']
    option_parser.on(
      " ",
      "--rabbitmq_url VALUE",
      "connection string to RabbitMQ 'amqp://user:pass@host:10000/vhost'"
    ) do |value|
      CarrotRpc.configuration.bunny = Bunny.new(value)
    end
  end

  def self.add_ruby_options(option_parser)
    option_parser.separator ""

    option_parser.separator "Ruby options:"

    option_parser.on("-I", "--include PATH", "an additional $LOAD_PATH") do |value|
      $LOAD_PATH.unshift(*value.split(":").map { |v| File.expand_path(v) })
    end

    option_parser.on("--debug", "set $DEBUG to true") do
      $DEBUG = true
    end

    option_parser.on("--warn", "enable warnings") do
      $-w = true
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def self.option_parser
    option_parser = OptionParser.new
    option_parser.banner =  "RPC Server Runner for RabbitMQ RPC Services."
    option_parser.separator ""
    option_parser.separator "Usage: server [options]"

    add_process_options(option_parser)
    add_ruby_options(option_parser)
    add_common_options(option_parser)

    option_parser.separator ""

    option_parser
  end

  def self.parse_options(args = ARGV)
    option_parser.parse!(args)
  end
end
