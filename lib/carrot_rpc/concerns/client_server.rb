# Common functionality for Client and Server.
module ClientServer
  module ClassMethods
    # Allows for class level definition of queue name. Default naming not performed. Class must pass queue name.
    def queue_name(name)
      @queue_name = name
    end

    # Accessor for queue name.
    def get_queue_name
      @queue_name
    end
  end
end
