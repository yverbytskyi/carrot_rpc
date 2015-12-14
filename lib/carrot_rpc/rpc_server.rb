require_relative "concerns/client_server"

# CarrotRpc gem base module.
module CarrotRpc
  # Base RPC Server class. Other Servers should inherit from this.
  class RpcServer
    attr_reader :channel, :server_queue
    # method_reciver => object that receives the method. can be a class or anything responding to send
    attr_accessor :logger

    extend ClientServer::ClassMethods

    # Documentation advises not to share a channel connection. Create new channel for each server instance.
    def initialize(config: nil, block: true)
      # create a channel and exchange that both client and server know about
      config ||= CarrotRpc.configuration
      @channel = config.bunny.create_channel
      @block = block
      @server_queue = @channel.queue(self.class.get_queue_name)
      @exchange  = @channel.default_exchange
    end

    # start da server!
    # method => object that receives the method. can be a class or anything responding to send
    def start
      # subscribe is like a callback
      @server_queue.subscribe(block: @block) do |delivery_info, properties, payload|
        logger.debug "Receiving message: #{payload}"
        request_message = JSON.parse(payload).with_indifferent_access
        result = self.send(request_message[:method], request_message[:params])
        reply(request_message: request_message, result: result, properties: properties)
      end
    end

    private
    # See http://www.jsonrpc.org/specification for more information on responses.
    # Method does not account for error messages. Need better handling to send proper errors.
    def reply(request_message:, result:, properties:)
      response_message = { id: request_message[:id], result: result, jsonrpc: '2.0' }
      logger.debug "Publishing result: #{result} to #{response_message}"
      @exchange.publish(response_message.to_json, routing_key: properties.reply_to,
                        correlation_id: properties.correlation_id)
    end
  end
end
