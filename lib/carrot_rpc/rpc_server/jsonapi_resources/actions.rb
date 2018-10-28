# The common CRUD actions for {CarrotRpc::RpcServer::JSONAPIResources}
module CarrotRpc::RpcServer::JSONAPIResources::Actions
  #
  # CONSTANTS
  #

  # Set of allowed actions for JSONAPI::Resources
  NAME_SET = Set.new(
    [
      # Mimic behaviour of `POST <collection>` routes
      :create,
      # Mimic behaviour of `POST <collection>/<id>/relationships/<relation>` routes
      :create_relationship,
      # Mimic behavior of `DELETE <collection>/<id>` routes
      :destroy,
      # Mimic behavior of `DELETE <collection>/<id>/relationships/<relationship>` routes
      :destroy_relationship,
      # Mimics behavior of `GET <collection>/<id>/<relationship>` routes
      :get_related_resource,
      # Mimic behavior of `GET <collection>` routes
      :index,
      # Mimic behavior of `GET <collection>/<id>` routes
      :show,
      # Mimic behavior of `GET <collection>/<id>/relationships/<relationship>` routes
      :show_relationship,
      # Mimic behavior of `PATCH|PUT <collection>/<id>` routes
      :update,
      # Mimic behavior of `PATCH|PUT <collection>/<id>/relationships/<relationship>` routes
      :update_relationship
    ]
  ).freeze

  #
  # Module Methods
  #

  # Defines an action method, `name` on `action_module`.
  #
  # @param action_module [Module] Module where action methods are defined so that they can be called with `super` if
  #   overridden.
  # @param name [Symbol] an element of `NAME_SET`.
  # @return [void]
  def self.define_action_method(action_module, name)
    action_module.send(:define_method, name) do |params|
      process_request_params(
        ActionController::Parameters.new(
          params.merge(
            action: name,
            controller: controller
          )
        )
      )
    end
  end

  #
  # Instance Methods
  #

  # Adds actions in `names` to the current class.
  #
  # The actions are added to a mixin module `self::Actions`, so that the action methods can be overridden and `super`
  # will work.
  #
  # @example Adding only show actions
  #     extend RpcServer::JSONAPIResources::Actions
  #     include RpcServer::JSONAPIResources
  #
  #     actions :create,
  #             :destroy,
  #             :index,
  #             :show,
  #             :update
  #
  # @param names [Array<Symbol>] a array of a subset of {NAME_SET}.
  # @return [void]
  # @raise (see #valid_actions)
  def actions(*names)
    valid_actions!(names)

    # an include module so that `super` works if the method is overridden
    action_module = Module.new

    names.each do |name|
      CarrotRpc::RpcServer::JSONAPIResources::Actions.define_action_method(action_module, name)
    end

    const_set(:Actions, action_module)

    include action_module
  end

  private

  # Checks that all `names` are valid action names.
  #
  # @raise [ArgumentError] if any element of `names` is not an element of `NAME_SET`.
  def valid_actions!(names)
    given_name_set = Set.new(names)
    unknown_name_set = given_name_set - NAME_SET

    unless unknown_name_set.empty?
      raise ArgumentError,
            "#{unknown_name_set.to_a.sort.to_sentence} are not elements of known actions " \
            "(#{NAME_SET.to_a.sort.to_sentence})"
    end
  end
end
