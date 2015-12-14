# Common functionality for Client and Server.
module ClientServer
  module ClassMethods
    # Allows for override of the default queue name.
    def queue_name(name)
      @queue_name = name
    end

    # Accessor for queue name.
    def get_queue_name
      @queue_name
    end
  end
end
