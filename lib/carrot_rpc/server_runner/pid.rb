# Pid and pid path for {CarrotRpc::ServerRunner}
class CarrotRpc::ServerRunner::Pid
  # Attributes

  # @return [Logger]
  attr_reader :logger

  # @return [String]
  attr_reader :path

  # Methods

  ## Class Methods

  # The status of the given `pid` number.
  #
  # @param pid [Integer] a 0 or positive PID
  # @return [:dead] if `pid` is `0`
  # @return (see number_error_check_status)
  def self.number_status(pid)
    if pid.zero?
      :dead
    else
      number_error_check_status(pid)
    end
  end

  # The status of the given `non_zero_pid` number.
  #
  # @param non_zero_pid [Integer] a non-zero pid
  # @return [:dead] if `pid` cannot be contacted
  # @return [:not_owned] if interacting with `pid` raises a permission error
  # @return [:running] if `pid` is running
  def self.number_error_check_status(non_zero_pid)
    # sending signal `0` just performs error checking
    Process.kill(0, non_zero_pid)
  rescue Errno::ESRCH
    # Invalid pid
    :dead
  rescue Errno::EPERM
    # no privilege to interact with process
    :not_owned
  else
    :running
  end

  # Status of the `pid` inside `path`.
  #
  # @return [:exited] if `path` does not exist, which indicates the server never ran or exited cleanly
  # @return [:not_owned] if `path` cannot be read
  # @return (see number_status)
  def self.path_status(path)
    pid = File.read(path).to_i
  rescue Errno::ENOENT
    # File does not exist
    :exited
  rescue Errno::EPERM
    # File cannot be read
    :not_owned
  else
    number_status(pid)
  end

  ## Initialize

  # @param path [Path, nil] path to pid path
  def initialize(path:, logger:)
    unless path.nil?
      # daemonization will change CWD so expand relative paths now
      @path = File.expand_path(path)
    end

    @logger = logger
  end

  ## Instance Methods

  # Exits if status indicates server is already running, otherwise deletes {#path}.
  #
  # @return [void]
  def check
    if path?
      case self.class.path_status(path)
      when :running, :not_owned
        logger.warn "A server is already running. Check #{path}"
        exit(1)
      when :dead
        delete
      end
    end
  end

  # Deletes `path` if it is set
  #
  # @return [void]
  def delete
    if path? && File.exist?(path)
      File.delete(path)
    end
  end

  # Registers an `at_exit` handler to {#delete}.
  #
  # @return [void]
  def delete_at_exit
    at_exit do
      delete
    end
  end

  # Keeps trying to write {#path} until it succeeds
  def ensure_written
    if path?
      begin
        write
      rescue Errno::EEXIST
        check

        retry
      else
        delete_at_exit
      end
    end
  end

  # Whether {#path} is set.
  #
  # @return [true] if {#path} is not `nil`.
  # @return [false] otherwise
  def path?
    !path.nil?
  end

  # Write to process id path
  #
  # @return [void]
  def write
    File.open(path, File::CREAT | File::EXCL | File::WRONLY) do |f|
      f.write(Process.pid.to_s)
    end
  end
end
