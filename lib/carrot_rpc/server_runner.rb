require "active_support/core_ext/string/inflections"

# Automatically detects, loads, and runs all {CarrotRpc::RpcServer} subclasses under `app/servers` in the project root.
class CarrotRpc::ServerRunner
  extend ActiveSupport::Autoload

  autoload :AutoloadRails
  autoload :Logger
  autoload :Pid
  autoload :Signal
  autoload :Signals

  # Attributes

  attr_reader :signal,
              :servers

  # @return [CarrotRpc::ServerRunner::Pid]
  attr_reader :pid

  # Methods

  # Instantiate the ServerRunner.
  def initialize(rails_path: ".", pidfile: nil, daemonize: false)
    self.signal = CarrotRpc::ServerRunner::Signal.new

    @daemonize = daemonize
    @servers = []

    CarrotRpc::ServerRunner::AutoloadRails.conditionally_load_root(rails_path, logger: logger)

    @pid = CarrotRpc::ServerRunner::Pid.new(
      path:   pidfile,
      logger: logger
    )
  end

  # Start the servers and the run loop.
  def run!
    CarrotRpc.connect

    signal.trap

    pid.check
    daemonize && suppress_output if daemonize?
    pid.ensure_written

    # Initialize the servers. Set logger.
    run_servers
    stop_servers(signal.wait)
  end

  # Shutdown all servers defined.
  def stop_servers(signal_name)
    logger.info "#{signal_name} signal received!"
    @servers.each do |s|
      logger.info "Shutting Down Server Queue: #{s.server_queue.name}"
      s.channel.close
    end
    # Close the connection once all the other servers are shutdown
    CarrotRpc.configuration.bunny.close
  end

  # Find and require all servers in the app/servers dir.
  # @param dirs [Array] directories relative to root of host application where RpcServers can be loaded
  # @return [Array] of RpcServers loaded and initialized
  def run_servers(dirs: %w[app servers])
    files = server_files(dirs)
    raise "No servers found!" if files.empty?

    # Load each server defined in the project dir
    files.each do |file|
      @servers << run_server_file(file)
    end

    @servers
  end

  def run_server_file(file)
    require file
    server_klass_name = file.to_s.split("/").last.gsub(".rb", "").camelize
    server_klass = server_klass_name.constantize

    stm = CarrotRpc.configuration.server_test_mode
    logger.info "Starting: #{server_klass} | Rails/Rack ENV: #{ENV['RAILS_ENV']} | Server Test Mode: #{stm}"

    server = server_klass.new(block: false)
    server.start

    server
  end

  def server_files(dirs)
    Dir[server_glob(dirs)]
  end

  def server_glob(dirs)
    regex = %r{\A/.*/#{dirs.join("/")}\z}
    $LOAD_PATH.find { |p|
      p.match(regex)
    } + "/*.rb"
  end

  # Convenience method to wrap the logger object.
  def logger
    @logger ||= set_logger
  end

  # attr_reader doesn't allow adding a `?` to the method name, so I think this is a false positive

  # Attribute to determine when to daemonize the process.
  def daemonize?
    @daemonize
  end

  # rubocop:enable Style/TrivialAccessors

  # Background the ruby process.
  def daemonize
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir "/"
  end

  # Part of daemonizing process. Prevents application from outputting info to terminal.
  def suppress_output
    $stderr.reopen("/dev/null", "a")
    $stdout.reopen($stderr)
  end

  private

  attr_writer :signal

  # Determine how to create logger. Config can specify log file.
  def set_logger
    logger = CarrotRpc::ServerRunner::Logger.configured
    CarrotRpc.configuration.logger = logger

    logger
  end

  def wait_for_shutdown
    loop do
      # Wait for quit message
      read_ready, _write_ready, _error_ready = IO.select([shutdown_reader])

      next unless read_ready.include? shutdown_reader

      shutdown_reader.read_nonblock(1)
      # When runtime gets here, quit signal is received.
      stop_servers
    end
  end
end
