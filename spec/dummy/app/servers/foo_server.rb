class FooServer
  attr_accessor :logger

  def initialize(block: false)
  end

  def start
    true
  end

  def to_s
    "FooServer"
  end
end
