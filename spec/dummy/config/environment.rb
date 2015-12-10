# Fake rails environment config
class Rails
  def self.application
    Application
  end

  def self.logger
    Logger.new(STDOUT)
  end

  class Application
    def self.eager_load!
    end
  end
end
