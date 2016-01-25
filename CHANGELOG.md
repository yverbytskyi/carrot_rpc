# Changelog
All significant changes in the project are documented here.

## v0.1.2

### Enhancements
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614]
  * Rename the keys in the parsed payload from '-' to '_'
  * Added integration specs to test functionality
  * Logging to test.log file
  * Setup for circleci integration tests to rabbitmq

### Bug Fixes
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614]
  * Some require statements not properly loading modules
  * Consistent use of require vs require_relative

## v0.1.1

### Enhancements
* [#1](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614]
  * `CarrotRpc.configuration.bunny` can be set to custom
    [`Bunny` instance](http://www.rubydoc.info/gems/bunny/Bunny#new-class_method).
  * `CarrotRpc::RpcClient` and `CarrotRpc::RpcServer` subclasses can set their queue name with the `queue_name` class
    method. (It can be retrieved with `get_queue_name`.
  * `carrot_rpc`'s `--autoload_rails` boolean flag determines whether to load Rails environment.  The Rails path is
    assumed to the be the current working directory.
  * If a `CarrotRpc::RpcServer` method invoked from a JSON RPC `:method` raises an `CarrotRpc::Error`, then that error
    is converted to a JSON RPC error and sent back to the client.

### Bug Fixes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [shamil614](https://github.com/shamil614]
  * Send `jsonrpc` key instead of incorrect `json_rpc` key in JSON RPC response messages
  * All files under `bin` are marked as gem executables instead of just `carrot_rpc`
  * Fix files not loading properly when using `carrot_rpc`
  * Fix bug in logger file setup
  * The logger for each `CarrotRpc::RpcServer` is set before the server is started in
    `CarrotRpc::ServerRunner#run_servers` to prevent a race condition where `#start` may try to use the logger.

### Incompatible Changes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [shamil614](https://github.com/shamil614]
  * `CarrotRpc.configuration.bunny` **MUST** be set to a
    [`Bunny` instance](http://www.rubydoc.info/gems/bunny/Bunny#new-class_method), usually using `Bunny.new`.
  * `CarrotRpc::RpcClient` and `CarrotRpc::RpcServer` subclasses **MUST** set their queue name with the `queue_name`
    class method.
  * `:channel` keyword argument is no longer accepted in `CarrotRpc::RpcClient.new`.  The channel had already been
    created from the `config.bunny.create_channel`, so the keyword argument was unused.
  * `CarrotRpc::RpcClient#logger` is now read-only and is set from `config.logger`.
  * `CarrotRpc::RpcServer#logger` is now read-only and is set from `config.logger`.
  * `CarrotRpc.configuration.logger` is set to the `CarrotRpc::ServerServer#logger`.
  * `carrot_rpc`'s `--rails_path PATH` flag has been replaced with `--autoload_rails` boolean flag that automatically
     assumes the Rails path is the current working directory.
  * `CarrotRpc.connfiguration.rails_path` no longer exists.  The Rails path is assumed to be the current working
    directory.
