# Traps all the signals {NAMES} that should be intercepted by a long-running background process.
module CarrotRpc::ServerRunner::Signals
  # CONSTANTS

  # The name of the signals to trap.
  NAMES = %w[HUP INT QUIT TERM].freeze

  # Traps all {NAMES}.
  #
  # @yield [name] Block to call when the signal is trapped.
  # @yieldparam name [String] the name of the signal that was trapped
  # @yieldreturn [void]
  # @return [void]
  def self.trap
    NAMES.each do |name|
      Kernel.trap(name) do
        yield name
      end
    end
  end
end
