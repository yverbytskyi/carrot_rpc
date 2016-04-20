# Base RPC Server class. Other Servers should inherit from this.
class CarrotRpc::RpcServer
  autoload :JSONAPIResources, "carrot_rpc/rpc_server/jsonapi_resources"

  using CarrotRpc::HashExtensions

  attr_reader :channel, :server_queue, :logger
  # method_reciver => object that receives the method. can be a class or anything responding to send

  extend CarrotRpc::ClientServer

  # Documentation advises not to share a channel connection. Create new channel for each server instance.
  def initialize(config: nil, block: true)
    # create a channel and exchange that both client and server know about
    config ||= CarrotRpc.configuration
    @channel = config.bunny.create_channel
    @logger = config.logger
    @block = block
    @server_queue = @channel.queue(self.class.queue_name)
    @exchange = @channel.default_exchange
  end

  # start da server!
  # method => object that receives the method. can be a class or anything responding to send
  def start
    # subscribe is like a callback
    @server_queue.subscribe(block: @block) do |_delivery_info, properties, payload|
      logger.debug "Receiving message: #{payload}"

      request_message = JSON.parse(payload).with_indifferent_access

      process_request(request_message, properties: properties)
    end
  end

  def process_request(request_message, properties:)
    result = send(request_message[:method], request_message[:params])
  rescue CarrotRpc::Error => rpc_server_error
    logger.error(rpc_server_error)

    reply_error rpc_server_error.serialized_message,
                properties:      properties,
                request_message: request_message
  else
    reply_result result,
                 properties:      properties,
                 request_message: request_message
  end

  private

  def reply(properties:, response_message:)
    @exchange.publish response_message.to_json,
                      correlation_id: properties.correlation_id,
                      routing_key: properties.reply_to
  end

  # See http://www.jsonrpc.org/specification#error_object
  def reply_error(error, properties:, request_message:)
    response_message = { error: error, id: request_message[:id], jsonrpc: "2.0" }

    logger.debug "Publish error: #{error} to #{response_message}"

    reply properties: properties,
          response_message: response_message
  end

  # See http://www.jsonrpc.org/specification#response_object
  def reply_result(result, properties:, request_message:)
    if result && result.is_a?(Hash) && result["errors"]
      reply_result_with_errors(result, properties: properties, request_message: request_message)
    else
      reply_result_without_errors(result, properties: properties, request_message: request_message)
    end
  end

  def reply_result_with_errors(result, properties:, request_message:)
    scrubbed_result = result.merge(
      "errors" => scrub_errors(result.fetch("errors"))
    )
    reply_error({ code: 422, data: scrubbed_result, message: "JSONAPI error" },
                properties: properties,
                request_message: request_message)
  end

  def reply_result_without_errors(result, properties:, request_message:)
    response_message = { id: request_message[:id], jsonrpc: "2.0", result: result }

    logger.debug "Publishing result: #{result} to #{response_message}"

    reply properties: properties,
          response_message: response_message
  end

  # Removes `nil` values as JSONAPI spec expects unset keys not to be transmitted
  def scrub_error(error)
    error.reject { |_, value|
      value.nil?
    }
  end

  # Removes `nil` values as JSONAPI spec expects unset keys not to be transmitted
  def scrub_errors(errors)
    errors.map { |error|
      scrub_error(error)
    }
  end
end
