# Stores a signal and allows for it to be waited on
class CarrotRpc::ServerRunner::Signal
  #
  # Attributes
  #

  attr_reader :name

  def initialize
    self.reader, self.writer = IO.pipe
  end

  #
  # Instance Methods
  #

  # Traps all {CarrotRpc::ServerRunner::Signals}.
  #
  # @return [void]
  def trap
    CarrotRpc::ServerRunner::Signals.trap do |name|
      # @note can't log from a trap context: since Ruby 2.0 traps don't allow mutexes as it could lead to a dead lock,
      #   so `logger.info` here would return "log writing failed. can't be called from trap context"
      receive(name)
    end
  end

  # Waits for a signal trapped by {#trap} to be received.
  #
  # @return [String]
  def wait
    loop do
      # Wait {#receive}.  IO.select can wake up
      read_ready, _write_ready, _error_ready = IO.select([reader])

      next unless read_ready.include? reader

      reader.read_nonblock(1)

      break name
    end
  end

  private

  attr_writer :name

  attr_accessor :reader,
                :writer

  # Sets `name` as the received signal
  #
  # @param name [String] name of the signal that was received from the trap
  # @return [void]
  def receive(name)
    self.name = name
    # any single byte works
    writer.write_nonblock(".")
  end
end
