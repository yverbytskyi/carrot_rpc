require "carrot_rpc/concerns/client_server"
require "carrot_rpc/concerns/hash_extensions"

# Generic class for all RPC Consumers. Use as a base class to build other RPC Consumers for related functionality.
# Let's define a naming convention here for subclasses becuase I don't want to write a Confluence doc.
# All subclasses should have the following naming convention: <Name>RpcConsumer  ex: PostRpcConsumer
module CarrotRpc
  class RpcClient
    using HashExtensions

    attr_reader :channel, :server_queue, :logger

    extend ClientServer::ClassMethods

    # Use defaults for application level connection to RabbitMQ
    # All RPC data goes over the same queue. I think that's ok....
    def initialize(config: nil)
      config ||= CarrotRpc.configuration
      @channel = config.bunny.create_channel
      @logger = config.logger
      # auto_delete => false keeps the queue around until RabbitMQ restarts or explicitly deleted
      @server_queue  = @channel.queue(self.class.queue_name, auto_delete: false)

      # Setup a direct exchange.
      @exchange = @channel.default_exchange
    end

    # Starts the connection to listen for messages.
    def start
      # Empty queue name ends up creating a randomly named queue by RabbitMQ
      # Exclusive => queue will be deleted when connection closes. Allows for automatic "cleanup".
      @reply_queue = @channel.queue("", exclusive: true)

      # setup a hash for results with a Queue object as a value
      @results = Hash.new{ |h, k| h[k] = Queue.new }

      # setup subscribe block to Service
      # block => false is a non blocking IO option.
      @reply_queue.subscribe(block: false) do |_delivery_info, properties, payload|
        result = JSON.parse(payload).rename_keys('-', '_').with_indifferent_access
        @results[properties[:correlation_id]].push(result[:result])
      end
    end

    # params is an array of method argument values
    # programmer implementing this class must know about the remote service
    # the remote service must have documented the methods and arguments in order for this pattern to work.
    # TODO: change to a hash to account for keyword arguments???
    #
    # @param remote_method [String, Symbol] the method to be called on current receiver
    # @param params [Hash] the arguments for the method being called.
    # @return [Object] the result of the method call.
    def remote_call(remote_method, params)
      correlation_id = SecureRandom.uuid
      message = {
        id: correlation_id,
        jsonrpc: '2.0',
        method: remote_method,
        params: params.except(:controller, :action)
      }
      # Reply To => make sure the service knows where to send it's response.
      # Correlation ID => identify the results that belong to the unique call made
      @exchange.publish(message.to_json, routing_key: @server_queue.name, correlation_id: correlation_id,
                                         reply_to: @reply_queue.name)
      result = @results[correlation_id].pop
      @results.delete correlation_id # remove item from hash. prevents memory leak.
      result
    end

    # Convience method as a resource alias for index action.
    # To customize, override the method in your class.
    #
    # @param params [Hash] the arguments for the method being called.
    def index(params)
      remote_call('index', params)
    end

    # Convience method as a resource alias for show action.
    # To customize, override the method in your class.
    #
    # @param params [Hash] the arguments for the method being called.
    def show(params)
      remote_call('show', params)
    end

    # Convience method as a resource alias for create action.
    # To customize, override the method in your class.
    #
    # @param params [Hash] the arguments for the method being called.
    def create(params)
      remote_call('create', params)
    end

    # Convience method as a resource alias for update action.
    # To customize, override the method in your class.
    #
    # @param params [Hash] the arguments for the method being called.
    def update(params)
      remote_call('update', params)
    end
  end
end
