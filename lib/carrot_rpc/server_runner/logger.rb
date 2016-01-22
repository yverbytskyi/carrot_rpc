# Constructs a logger based on the {CarrotRpc.configuration} and Rails environment
module CarrotRpc::ServerRunner::Logger
  # A `Logger` configured based on `CarrotRpc.configuration.logfile` and `CarrotRpc.configuration.loglevel`
  #
  # Fallbacks:
  # * `Rails.logger` if `Rails` is loaded
  # * `Logger` to `STDOUT` if `Rails` is not loaded
  #
  # @return [Logger]
  def self.configured
    logger = from_file

    if logger.nil?
      logger = if defined?(::Rails)
                 CarrotRpc::TaggedLog.new(logger: Rails.logger, tags: ["Carrot RPC"])
               else
                 Logger.new(STDOUT)
               end
    end

    logger.level = CarrotRpc.configuration.loglevel

    logger
  end

  def self.from_file
    return nil unless CarrotRpc.configuration.logfile

    ::Logger.new(CarrotRpc.configuration.logfile)
  end
end
