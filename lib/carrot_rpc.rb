require "carrot_rpc/version"
require "bunny"
require "carrot_rpc/cli"
require "carrot_rpc/configuration"
require "carrot_rpc/tagged_log"
require "carrot_rpc/rpc_client"
require "carrot_rpc/rpc_server"
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/except'
require 'json'

module CarrotRpc
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
