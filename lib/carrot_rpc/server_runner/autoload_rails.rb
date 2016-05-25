# Loads the Rails application so that the servers can use the Rails gems and environment.
module CarrotRpc::ServerRunner::AutoloadRails
  # Path to the `config/environment.rb`, which is the file that must actually be `require`d to load Rails.
  #
  # @param root [String] path to the root of the Rails app
  # @return [String]
  def self.environment_path(root)
    File.join(root, "config/environment.rb")
  end

  # Attempts to load Rails app at `root`.
  #
  # @param root [String] path to the root of the Rails app
  # @param logger [Logger] logger to print success to.
  # @return [true]
  # @raise [LoadError] if rails cannot be loaded
  def self.load_root(root, logger:)
    rails_path = environment_path(root)

    if File.exist?(rails_path)
      logger.info "Rails app found at: #{rails_path}"
      set_rack_rails_env
      require rails_path
      ::Rails.application.eager_load!
      true
    else
      require rails_path
    end
  end

  # Loads Rails app at `root` if `CarrotRpc.configuration.autoload_rails`
  #
  # @param (see load_root)
  # @return (see load_root)
  # @raise (see load_root)
  def self.conditionally_load_root(root, logger:)
    if CarrotRpc.configuration.autoload_rails
      load_root(root, logger: logger)
    end
  end

  # Set Rails/Rack env vars to test when server test mode is enabled.
  #
  # @return [Void]
  def self.set_rack_rails_env
    if CarrotRpc.configuration.server_test_mode
      env_mode = "test"
      ENV["RACK_ENV"] = ENV["RAILS_ENV"] = env_mode
    else
      env_mode = "development"
      ENV["RACK_ENV"] ||= ENV["RAILS_ENV"] ||= env_mode
    end
  end
end
