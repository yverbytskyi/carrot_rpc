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

  # index RPC method
  def index
    process_request_params(
      action: :index,
      controller: controller
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
