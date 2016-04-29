# An enum of predefined error codes.
module CarrotRpc::Error::Code
  # Internal JSON-RPC error.
  INTERNAL_ERROR   = -32_603

  # Invalid method parameter(s).
  INVALID_PARAMS   = -32_602

  # The JSON sent is not a valid Request object.
  INVALID_REQUEST  = -32_600

  # The method does not exist / is not available.
  METHOD_NOT_FOUND = -32_601

  # Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.
  PARSE_ERROR      = -32_700
end
