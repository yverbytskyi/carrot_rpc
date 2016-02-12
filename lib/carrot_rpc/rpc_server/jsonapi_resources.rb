# frozen_string_literal: true

# Allows a {CarrotRpc::RpcServer} subclass to behave the same as a controller that does
# `include JSONAPI::ActsAsResourceController`
module CarrotRpc::RpcServer::JSONAPIResources
  autoload :Actions, "carrot_rpc/rpc_server/jsonapi_resources/actions"

  # The base "meta" to include in the top-level of all JSON API documents.
  #
  # @param request [JSONAPI::Request] the current request.  `JSONAPI::Request#warnings` are merged into the
  #   {#base_response_meta}.
  # @return [Hash]
  def base_meta(request)
    if request.nil? || request.warnings.empty?
      base_response_meta
    else
      base_response_meta.merge(warnings: request.warnings)
    end
  end

  # The base "links" to include the top-level of all JSON API documents before any operation result links are added.
  #
  # @return [Hash] Defaults to `{}`.
  def base_response_links
    {}
  end

  # The base "meta" to include in the top-level of all JSON API documents before being merged with any request warnings
  # in {#base_meta}.
  #
  # @return [Hash] Defaults to `{}`.
  def base_response_meta
    {}
  end

  # The operations processor in the configuration or override this to use another operations processor
  #
  # @return [JSONAPI::OperationsProcessor]
  def create_operations_processor
    JSONAPI.configuration.operations_processor.new
  end

  # The JSON API Document for the `operation_results` and `request`.
  #
  # @param operation_results [JSONAPI::OperationResults] The result of processing the `request`.
  # @param request [JSONAPI::Request] the request to respond to.
  # @return [JSONAPI::ResponseDocument]
  def create_response_document(operation_results:, request:) # rubocop:disable  Metrics/MethodLength
    JSONAPI::ResponseDocument.new(
      operation_results,
      primary_resource_klass: resource_klass,
      include_directives: request ? request.include_directives : nil,
      fields: request ? request.fields : nil,
      base_url: base_url,
      key_formatter: key_formatter,
      route_formatter: route_formatter,
      base_meta: base_meta(request),
      base_links: base_response_links,
      resource_serializer_klass: resource_serializer_klass,
      request: request,
      serialization_options: serialization_options
    )
  end

  # @note Override this to process other exceptions. Be sure to either call `super(exception)` or handle
  #   `JSONAPI::Exceptions::Error` and `raise` unhandled exceptions.
  #
  # @param exception [Exception] the original, exception that was caught
  # @param request [JSONAPI::Request] the request that triggered the `exception`
  # @return (see #render_errors)
  def handle_exceptions(exception, request:)
    case exception
    when JSONAPI::Exceptions::Error
      render_errors(exception.errors, request: request)
    else
      internal_server_error = JSONAPI::Exceptions::InternalServerError.new(exception)
      logger.error { # rubocop:disable Style/BlockDelimiters
        "Internal Server Error: #{exception.message} #{exception.backtrace.join("\n")}"
      }
      render_errors(internal_server_error.errors)
    end
  end

  # @note Override if you want to set a per controller key format.
  #
  # Control by setting in an initializer:
  #     JSONAPI.configuration.json_key_format = :camelized_key
  #
  # @return [JSONAPI::KeyFormatter]
  def key_formatter
    JSONAPI.configuration.key_formatter
  end

  # Processes the params as a request and renders a response.
  #
  # @param params [ActionController::Parameter{action: Symbol, controller: String}] **MUST** set `:action` to the action
  #   name so that `JSONAPI::Request#setup_action` can dispatch to the correct `setup_*_action` method.  **MUST** set
  #   `:controller` to a URL name for the controller, such as `"api/v1/partner"`, so that the resource can be looked up
  #   by the controller name.
  # @return [Hash] rendered, but not encoded JSON.
  def process_request_params(params) # rubocop:disable Metrics/MethodLength
    request = JSONAPI::Request.new(
      params,
      context: {},
      key_formatter: key_formatter,
      server_error_callbacks: []
    )

    if !request.errors.empty?
      render_errors(request.errors, request: request)
    else
      operation_results = create_operations_processor.process(request)
      render_results(
        operation_results: operation_results,
        request: request
      )
    end
  rescue => e
    handle_exceptions(e, request: request)
  end

  # Renders the `errors` as a JSON API errors Document.
  #
  # @param errors [Array<JSONAPI::Error>] errors to use in a JSON API errors Document
  # @param request [JSONAPI::Request] the request that caused the `errors`.
  # @return [Hash] rendered, but not encoded JSON
  def render_errors(errors, request:)
    operation_results = JSONAPI::OperationResults.new
    result = JSONAPI::ErrorsOperationResult.new(errors[0].status, errors)
    operation_results.add_result(result)

    render_results(
      operation_results: operation_results,
      request: request
    )
  end

  # Renders the `operation_results` as a JSON API Document.
  #
  # @param operation_results [JSONAPI::OperationResults] a collection of results from various operations.
  # @param request [JSONAPI::Request] the original request that generated the `operation_results`.
  # @return [Hash] rendered, but not encoded JSON
  def render_results(operation_results:, request:)
    response_document = create_response_document(
      operation_results: operation_results,
      request: request
    )
    response_document.contents.as_json
  end

  # Class to serialize `JSONAPI::Resource`s to JSON API documents.
  #
  # @return [Class<JSONAPI::ResourceSerializer>]
  def resource_serializer_klass
    @resource_serializer_klass ||= JSONAPI::ResourceSerializer
  end

  # Control by setting in an initializer:
  #     JSONAPI.configuration.route = :camelized_route
  #
  # @return [JSONAPI::RouteFormatter]
  def route_formatter
    JSONAPI.configuration.route_formatter
  end

  # Options passed to `resource_serializer_klass` instance when serializing the JSON API document.
  #
  # @return [Hash] Defaults to `{}`
  def serialization_options
    {}
  end
end
