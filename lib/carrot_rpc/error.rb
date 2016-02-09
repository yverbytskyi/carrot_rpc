# Error raised by an {RpcServer} method to signal that a
# {http://www.jsonrpc.org/specification#error_object JSON RPC 2.0 Response Error object} should be the reply.
class CarrotRpc::Error < StandardError
  autoload :Code, "carrot_rpc/error/code"

  # @return [Integer]A Number that indicates the error type that occurred. Some codes are
  #   {http://www.jsonrpc.org/specification#error_object predefined}.
  attr_reader :code

  # @return [Object, nil] A Primitive or Structured value that contains additional information about the error.
  #   This may be omitted. The value of this member is defined by the Server (e.g. detailed error information,
  #   nested errors etc.).
  attr_reader :data

  # @param code [Integer] A Number that indicates the error type that occurred.  Favor using the
  #   {http://www.jsonrpc.org/specification#error_object predefined codes}.
  # @param message [String] A String providing a short description of the error. The message SHOULD be limited to a
  #   concise single sentence.
  # @param data [Object, nil] A Primitive or Structured value that contains additional information about the error.
  #   This may be omitted. The value of this member is defined by the Server (e.g. detailed error information,
  #   nested errors etc.).
  def initialize(code:, message:, data: nil)
    @code = code
    @data = data
    super(message)
  end

  # A properly formatted {http://www.jsonrpc.org/specification#error_object JSON RPC Error object}.
  #
  # @return [Hash{code: String, message: String}, Hash{code: String, data: Object, message: String}]
  def serialized_message
    serialized = {
      code: code,
      message: message
    }

    if data
      serialized[:data] = data
    end

    serialized
  end
end
