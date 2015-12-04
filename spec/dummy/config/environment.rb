# Fake rails environment config
class Rails
  def self.application
    Application
  end

  class Application
    def self.eager_load!
    end
  end
end
