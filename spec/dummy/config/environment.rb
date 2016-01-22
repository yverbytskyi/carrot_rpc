# standard library
require "stringio"

# gems
require "active_support/logger"
require "active_support/tagged_logging"

# Fake rails environment config
module Rails
  class << self
    attr_accessor :logger_string_io
  end

  def self.application
    Application
  end

  def self.logger
    @logger ||= ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(logger_string_io))
  end

  def self.logger_string_io
    @logger_string_io ||= StringIO.new
  end

  class Application
    def self.eager_load!
    end
  end
end
