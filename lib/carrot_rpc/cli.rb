require 'bunny'
require 'optparse'

module CarrotRpc
  class CLI
    # Class methods
    class << self
      def self.run!(argv = ARGV)
        parse_options(argv)
      end

      def parse_options(args = ARGV)
        # Set defaults below.
        options             = { }
        version             = "1.0.0"
        daemonize_help      = "run daemonized in the background (default: false)"
        runloop_sleep_help  = "Configurable sleep time in the runloop"
        pidfile_help        = "the pid filename"
        include_help        = "an additional $LOAD_PATH"
        debug_help          = "set $DEBUG to true"
        warn_help           = "enable warnings"
        rails_path_help     = "relative path to root dir of rails app. Uses Rails Logger by default."
        logfile_help        = "relative path and name for Log file. Overrides all defaults."
        loglevel_help       = "levels of loggin: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN"
        rabbitmq_url_help   = "connection string to RabbitMQ 'amqp://user:pass@host:10000/vhost'"

        op = OptionParser.new
        op.banner =  "RPC Server Runner for RabbitMQ RPC Services."
        op.separator ""
        op.separator "Usage: server [options]"
        op.separator ""

        op.separator "Process options:"
        op.on("-d", "--daemonize",   daemonize_help) do
          CarrotRpc.configuration.daemonize = true
        end

        op.on(" ", "--pidfile PIDFILE", pidfile_help) do |value|
          CarrotRpc.configuration.pidfile = value
        end

        op.on("-s", "--runloop_sleep VALUE", Float, runloop_sleep_help)  do |value|
          CarrotRpc.configuration.runloop_sleep = value
        end

        # Expand path here because this file is not likely to move.
        op.on(" ", "--rails_path PATH", rails_path_help) do |value|
          CarrotRpc.configuration.rails_path = File.expand_path(value, __FILE__)
        end

        op.on(" ", "--logfile VALUE", logfile_help) do |value|
          CarrotRpc.configuration.logfile = File.expand_path("../../#{value}", __FILE__)
        end

        op.on(" ", "--loglevel VALUE", loglevel_help) do |value|
          level = eval(["Logger", value].join("::")) || 0
          CarrotRpc.configuration.loglevel = level
        end

        # Optional. Defaults to using the ENV['RABBITMQ_URL']
        op.on(" ", "--rabbitmq_url VALUE", rabbitmq_url_help) do |value|
          CarrotRpc.configuration.bunny = Bunny.new(value)
        end

        op.separator ""

        op.separator "Ruby options:"
        op.on("-I", "--include PATH", include_help) { |value| $LOAD_PATH.unshift(*value.split(":").map{|v| File.expand_path(v)}) }
        op.on(      "--debug",        debug_help)   { $DEBUG = true }
        op.on(      "--warn",         warn_help)    { $-w = true    }
        op.separator ""

        op.separator "Common options:"
        op.on("-h", "--help")    { puts op.to_s; exit }
        op.on("-v", "--version") { puts version; exit }
        op.separator ""
        op.parse!(args)
      end
    end
  end
end
