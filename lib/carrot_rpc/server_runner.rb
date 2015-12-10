require "carrot_rpc"
module CarrotRpc
  class ServerRunner
    attr_reader :quit, :servers

    # Instantiate the ServerRunner.
    def initialize(rails_path: nil, pidfile: nil, runloop_sleep: 0, daemonize: false)
      @runloop_sleep = runloop_sleep
      @daemonize = daemonize
      @servers = []
      load_rails_app(rails_path) if rails_path
      trap_signals

      # daemonization will change CWD so expand relative paths now
      @pidfile = File.expand_path(pidfile) if pidfile
    end

    # Start the servers and the run loop.
    def run!
      check_pid
      daemonize and suppress_output if daemonize?
      write_pid

      # Initialize the servers. Set logger.
      run_servers

      # Sleep for a split second.
      while !quit
        sleep @runloop_sleep
      end
      # When runtime gets here, quit signal is received.
      stop_servers
    end

    # Shutdown all servers defined.
    def stop_servers
      logger.info "Quit signal received!"
      @servers.each do |s|
        logger.info "Shutting Down Server Queue: #{s.queue.name}"
        s.channel.close
      end
      # Close the connection once all the other servers are shutdown
      CarrotRpc.configuration.bunny.connection.close
    end

    # Find and require all servers in the app/servers dir.
    # @param path [String] relative path to rpc servers
    # @param dirs [Array] directories where RpcServers can be loaded
    # @return [Array] of RpcServers loaded and initialized
    def run_servers(path: ".", dirs: ["app", "servers"])
      # Load each server defined in the project dir
      path = "#{path}#{dirs.join("/")}/*.rb"
      Dir[File.expand_path(path, File.dirname(__FILE__))].each do |file|
        require file
        server_klass = eval file.to_s.split('/').last.gsub('.rb', '').split("_").collect!{ |w| w.capitalize}.join
        logger.info "Starting #{server_klass}..."

        server = server_klass.new(block: false)
        server.start
        server.logger = logger
        @servers << server
      end
      @servers
    end

    # Convenience method to wrap the logger object.
    def logger
      puts @logger
      @logger ||= set_logger
    end

    # Path should already be expanded.
    def load_rails_app(path)
      rails_path = File.join(path, 'config/environment.rb')
      if File.exists?(rails_path)
        ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || 'development'
        require rails_path
        ::Rails.application.eager_load!
        true
      else
        require rails_path
      end
    end

    # Attribute to determine when to daemonize the process.
    def daemonize?
      @daemonize
    end

    # Attribute accessor for pid file options
    def pidfile
      @pidfile
    end

    # pid file present?
    def pidfile?
      !pidfile.nil?
    end

    # Write to process id file is one does not exist.
    def write_pid
      if pidfile?
        begin
          File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
          at_exit { File.delete(pidfile) if File.exists?(pidfile) }
        rescue Errno::EEXIST
          check_pid
          retry
        end
      end
    end

    # Determine if a process id file is already present.
    def check_pid
      if pidfile?
        case pid_status(pidfile)
        when :running, :not_owned
          logger.warn "A server is already running. Check #{pidfile}"
          exit(1)
        when :dead
          File.delete(pidfile)
        end
      end
    end

    # Set the process id file. Required for backgrounding.
    def pid_status(pidfile)
      return :exited unless File.exists?(pidfile)
      pid = ::File.read(pidfile).to_i
      return :dead if pid == 0
      Process.kill(0, pid)      # check process status
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    # Background the ruby process.
    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir "/"
    end

    # Part of daemonizing process. Prevents application from outputting info to terminal.
    def suppress_output
      $stderr.reopen('/dev/null', 'a')
      $stdout.reopen($stderr)
    end

    # Set a value to signal shutdown.
    def shutdown
      @quit = true
    end

    # Handle signal events.
    def trap_signals
      # graceful shutdown of run! loop
      trap(:QUIT) do
        logger.info "QUIT Little bunny foo foo is a Goon....closing connection to RabbitMQ"
        shutdown
      end
      # Handle Ctrl-C
      trap("INT") do
        logger.info "INT Little bunny foo foo is a Goon....closing connection to RabbitMQ"
        shutdown
      end

      # Handle Hangup
      trap("HUP") do
        logger.info "HUP Little bunny foo foo is a Goon....closing connection to RabbitMQ"
        shutdown
      end

      # Handles `Kill` signals
      trap("TERM") do
        # Documentation says closing connection will first close the channels belonging to the connection
        # Alternatively a channel can be closed independently ```channel.close```
        logger.info "TERM Little bunny foo foo is a Goon....closing connection to RabbitMQ"
        shutdown
      end
    end

    private

    # Determine how to create logger.
    def set_logger
      # when rails is defined, use that logger by default.
      # otherwise use the logger from the config
      if CarrotRpc.configuration.logfile
        logger = Logger.new(CarrotRpc.configuration.logfile)
        logger.level = CarrotRpc.configuration.loglevel
      elsif defined?(::Rails)
        logger = Rails.logger
        CarrotRpc::TaggedLog.new(logger: use_or_create_logger, tags: ["Carrot RPC"])
      else
        logger = Logger.new(STDOUT)
        logger.level = CarrotRpc.configuration.loglevel
      end
      logger
    end
  end
end
