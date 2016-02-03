# The common CRUD actions for {CarrotRpc::RpcServer::JSONAPIResources}
module CarrotRpc::RpcServer::JSONAPIResources::Actions
  # create RPC method
  def create(params)
    process_request_params(
      # ActionController::Parameters#require is used by JSONAPI::Request#setup_create_action
      ActionController::Parameters.new(
        params.merge(
          action: :create,
          controller: controller
        )
      )
    )
  end

  # Mimics behavior of `<collection>/<id>/<relationship>` routes
  def get_related_resource(params)
    process_request_params(
      # ActionController::Parameters#require is used by JSONAPI::Request#setup_get_related_resource_action
      ActionController::Parameters.new(
        params.merge(
          action: :get_related_resource,
          controller: controller
        )
      )
    )
  end

  # index RPC method
  def index(params)
    process_request_params(
      params.merge(
        action: :index,
        controller: controller
      )
    )
  end

  # show RPC method
  def show(params)
    process_request_params(
      params.merge(
        action: :show,
        controller: controller
      )
    )
  end

  # Mimic behavior of `<collection>/<id>/relationships/<relationship>` routes
  def show_relationship(params)
    process_request_params(
      # ActionController::Parameters#require is used by JSONAPI::Request#setup_show_relationship_action
      ActionController::Parameters.new(
        params.merge(
          action: :show_relationship,
          controller: controller
        )
      )
    )
  end

  # update RPC method
  def update(params)
    process_request_params(
      # ActionController::Parameters#require is used by JSONAPI::Request#setup_update_action
      ActionController::Parameters.new(
        params.merge(
          action: :update,
          controller: controller
        )
      )
    )
  end
end
