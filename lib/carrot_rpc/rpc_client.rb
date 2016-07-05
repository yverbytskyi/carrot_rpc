require "securerandom"

# Generic class for all RPC Consumers. Use as a base class to build other RPC Consumers for related functionality.
# Let's define a naming convention here for subclasses becuase I don't want to write a Confluence doc.
# All subclasses should have the following naming convention: <Name>RpcConsumer  ex: PostRpcConsumer
class CarrotRpc::RpcClient
  using CarrotRpc::HashExtensions

  attr_reader :channel, :server_queue, :logger

  extend CarrotRpc::ClientServer
  include CarrotRpc::ClientActions

  def self.before_request(*proc)
    if proc.length == 0
      @before_request
    elsif proc.length == 1
      @before_request = proc.first || CarrotRpc.configuration.before_request
    else
      fail ArgumentError
    end
  end

  # Logic to process the renaming of keys in a hash.
  # @param format [Symbol] :dasherize changes keys that have "_" to "-"
  # @param format [Symbol] :underscore changes keys that have "-" to "_"
  # @param format [Symbol] :skip, will not rename the keys
  # @param data [Hash] data structure to be transformed
  # @return [Hash] the transformed data
  def self.format_keys(format, data)
    case format
    when :dasherize
      data.rename_keys("_", "-")
    when :underscore
      data.rename_keys("-", "_")
    when :none
      data
    else
      data
    end
  end

  # Use defaults for application level connection to RabbitMQ.
  #
  # @example pass custom {Configuration} class as an argument to override.
  #   config = CarrotRpc::Configuration.new
  #   config.rpc_client_timeout = 10
  #   CarrotRpc::RpcClient.new(config)
  def initialize(config = nil)
    @config = config || CarrotRpc.configuration
    @logger = @config.logger
  end

  # Starts the connection to listen for messages.
  #
  # All RpcClient requests go to the a single @server_queue
  # Responses come back over a unique queue name.
  def start
    # Create a new channel on each request because the channel should be closed after each request.
    @channel = @config.bunny.create_channel

    queue_name = self.class.test_queue_name(self.class.queue_name, @config.client_test_mode)
    # auto_delete => false keeps the queue around until RabbitMQ restarts or explicitly deleted
    @server_queue = @channel.queue(queue_name, auto_delete: false)

    # Setup a direct exchange.
    @exchange = @channel.default_exchange
  end

  def subscribe
    # Empty queue name ends up creating a randomly named queue by RabbitMQ
    # Exclusive => queue will be deleted when connection closes. Allows for automatic "cleanup".
    @reply_queue = @channel.queue("", exclusive: true)

    # setup a hash for results with a Queue object as a value
    @results = Hash.new { |h, k| h[k] = Queue.new }

    # setup subscribe block to Service
    # block => false is a non blocking IO option.
    @reply_queue.subscribe(block: false) do |_delivery_info, properties, payload|
      logger.with_correlation_id(properties[:correlation_id]) do
        logger.debug "Receiving response: #{payload}"

        response = JSON.parse(payload).with_indifferent_access

        result = parse_response(response)
        result = response_key_formatter(result).with_indifferent_access if result.is_a? Hash
        @results[properties[:correlation_id]].push(result)
      end
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
    start
    subscribe
    correlation_id = SecureRandom.uuid
    logger.with_correlation_id(correlation_id) do
      params = self.class.before_request.call(params) if self.class.before_request
      publish(correlation_id: correlation_id, method: remote_method, params: request_key_formatter(params))
      wait_for_result(correlation_id)
    end
  end

  def wait_for_result(correlation_id)
    # Should be good to timeout here because we're blocking in the main thread here.
    Timeout.timeout(@config.rpc_client_timeout, CarrotRpc::Exception::RpcClientTimeout) do
      # `pop` is `Queue#pop`, so it is blocking on the receiving thread
      # and this must happend before the `Hash.delete` or
      # the receiving thread won't be able to find the correlation_id in @results
      result = @results[correlation_id].pop
      @results.delete correlation_id # remove item from hash. prevents memory leak.
      result
    end
  ensure
    @channel.close
  end

  # Formats keys in the response data.
  # @param payload [Hash] response data received from the remote server.
  # @return [Hash] formatted data structure.
  def response_key_formatter(payload)
    self.class.format_keys @config.rpc_client_response_key_format, payload
  end

  # Formats keys in the request data.
  # @param payload [Hash] request data to be sent to the remote server.
  # @return [Hash] formatted data structure.
  def request_key_formatter(params)
    self.class.format_keys @config.rpc_client_request_key_format, params
  end

  # A @reply_queue is deleted when the channel is closed.
  # Closing the channel accounts for cleanup of the client @reply_queue.
  def publish(correlation_id:, method:, params:)
    message = message(
      correlation_id: correlation_id,
      params:         params,
      method:         method
    )
    payload = message.to_json
    # Reply To => make sure the service knows where to send it's response.
    # Correlation ID => identify the results that belong to the unique call made
    logger.debug "Publishing request: #{payload}"
    @exchange.publish payload,
                      correlation_id: correlation_id,
                      reply_to:       @reply_queue.name,
                      routing_key:    @server_queue.name
  end

  def message(correlation_id:, method:, params:)
    {
      id:      correlation_id,
      jsonrpc: "2.0",
      method:  method,
      params:  params.except(:controller, :action)
    }
  end

  private

  # Logic to find the data from the RPC response.
  # @param [Hash] response from rpc call
  # @return [Hash,nil]
  def parse_response(response)
    # successful response
    if response.key?(:result)
      response[:result]
    # data is the key holding the error information
    elsif response.key?(:error)
      response[:error][:data]
    else
      response
    end
  end
end
