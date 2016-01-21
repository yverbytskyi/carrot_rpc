# gem dependencies
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/except"
require "active_support/dependencies/autoload"
require "bunny"

# standard library
require "json"
require "optparse"

# project
require "carrot_rpc/version"

module CarrotRpc
  extend ActiveSupport::Autoload

  autoload :CLI
  autoload :ClientServer
  autoload :Configuration
  autoload :HashExtensions
  autoload :RpcClient
  autoload :RpcServer
  autoload :ServerRunner
  autoload :TaggedLog

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Resets the configuration back to a new instance. Should only be used in testing.
  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield configuration
  end
end
