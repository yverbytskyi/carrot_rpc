# Wrap the Logger object with convenience methods.
class CarrotRpc::TaggedLog
  attr_reader :logger, :tags

  def initialize(logger:, tags:)
    @logger = logger
    @tags = *tags
  end

  def level
    logger.level
  end

  def level=(level)
    logger.level = level
  end

  # Dyanmically define logger methods with a tagged reference. Makes filtering of logs possible.
  %i[debug info warn error fatal unknown].each do |level|
    define_method(level) do |msg = nil, &block|
      logger.tagged(tags) { logger.send(level, msg || block.call) }
    end
  end

  delegate :tagged, to: :logger

  def with_correlation_id(correlation_id, &block)
    tagged("correlation_id=#{correlation_id}", &block)
  end
end
