# An enum of predefined {RpcServer::Server#code}
module CarrotRpc::Error::Code
  # Internal JSON-RPC error.
  INTERNAL_ERROR   = -32603

  # Invalid method parameter(s).
  INVALID_PARAMS   = -32602

  # The JSON sent is not a valid Request object.
  INVALID_REQUEST  = -32600

  # The method does not exist / is not available.
  METHOD_NOT_FOUND = -32601

  # Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.
  PARSE_ERROR      = -32700
end
