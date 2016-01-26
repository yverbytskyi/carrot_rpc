<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Changelog](#changelog)
  - [v0.2.0](#v020)
    - [Enhancements](#enhancements)
    - [Bug Fixes](#bug-fixes)
    - [Incompatible Changes](#incompatible-changes)
  - [v0.1.2](#v012)
    - [Enhancements](#enhancements-1)
    - [Bug Fixes](#bug-fixes-1)
  - [v0.1.1](#v011)
    - [Enhancements](#enhancements-2)
    - [Bug Fixes](#bug-fixes-2)
    - [Incompatible Changes](#incompatible-changes-1)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Changelog
All significant changes in the project are documented here.

## v0.2.1

### Bug Fixes
* [#6](https://github.com/C-S-D/carrot_rpc/pull/6) - [shamil614](https://github.com/shamil614)
  * Error class not loaded in RpcServer
  * RpcServer should not rename json keys
  * RpcClient dasherizes keys before serializing hash to json. Better conformity to json property naming conventions.
  * RpcClient underscores keys after receiving response from server. Better conformity to ruby naming conventions.


## v0.2.0

### Enhancements
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [KronicDeth](http://github.com/KronicDeth)
  * Gems ordered and documented in gemspec and `Gemfile`
  * Temorpary (`#`) files removed from git
  * Rubocop is enabled and used on CircleCI
    * Unused variables are prefixed with `_`
    * `fail` is used instead of `raise` when first raising an exception
    * Remove usage of deprecated methods
    * Print error if `byebug` can't be loaded instead of failing silently, but CLI still starts
    * Stop shadowing outer local variables in blocks
    * Remove unused assignments
    * Set and enforce max line length to 120
    * Use `find` instead of `select {}.first` for better performance
    * `queue_name` will retrieve the current queue name while `queue_name(new_name)` will set it.
    * Align hashes
    * Align parameters
    * Favor symbolic `&&` over `and`. (They have different precedence too)
    * Remove block comments
    * Assign to variable outside conditionals instead of on each branch
    * Remove extra empty lines
    * Don't favor guard clauses as they prevent break pointing the body and guard separately and obscure bodies that don't have code coverage.
    * Remove extra spacing
    * Correct indentation
    * Freeze `CarrotRpc::VERSION` so it is immutable
    * Use `until` instead of negated `while`
    * Use `_` to separate digits in large numerals
    * Use `( )` for sigils
    * Remove redundant `self.` for method calls
    * Use `%r{}` instead of `//` for regexps
    * Use newlines instead of `;`
    * Add spacing around blocks and braces
    * Enforce double quotes for all strings as double quotes work for strings in both Ruby and Elixir. (Single quotes are for Char Lists in Elixir)
    * Use `&:<method>` instead of calling a non-args method in blocks
    * Use `attr_reader` instead of trivial accessor methods
    * Remove unneed interpolation
    * Use double quotes instead of `%q`
    * Use `%w` for word arrays
    * Extract methods to lower to AbcSize metric and Method Length
    * Extract classes and modules to lower Class Length
    * Use `const_get` and `constantize` instead of security risk `eval`
  * Enable all RSpec 3 recommended options
    * Fix order-dependency of specs.
  * Use `autoload` to delay loading
  * Use compact class and module children to prevent parent from being missed when loading.
  * Add `rake spec`
  * Add Luke Imhoff as an author
  * Set gem home page to this repository
  * Semantic block delimiters, so we always think about procedural vs functional blocks to make Elixir coding easier.

### Bug Fixes
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [KronicDeth](http://github.com/KronicDeth)
  * `ClientServer::ClassMethods` has been moved under `CarrotRpc` namespace as `CarrotRpc::ClientServer`
  * `HashExtensions` has been moved under `CarrotRpc` namespace as `CarrotRpc::HashExtensions`

### Incompatible Changes
* [#5](https://github.com/C-S-D/carrot_rpc/pull/5) - [KronicDeth](http://github.com/KronicDeth)
  * `ClientServer::ClassMethods` renamed to `CarrotRpc::ClientServer`
  * `HashExtensions` renamed to `CarrotRpc::HashExtensions`
  * `ClientServer::ClassMethods#get_queue_name` renamed to `CarrotRpc::ClientServer#queue_name()` (no args is the reader, one argument is the writer)

## v0.1.2

### Enhancements
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614)
  * Rename the keys in the parsed payload from '-' to '_'
  * Added integration specs to test functionality
  * Logging to test.log file
  * Setup for circleci integration tests to rabbitmq

### Bug Fixes
* [#4](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614)
  * Some require statements not properly loading modules
  * Consistent use of require vs require_relative

## v0.1.1

### Enhancements
* [#1](https://github.com/C-S-D/carrot_rpc/pull1) - [shamil614](https://github.com/shamil614)
  * `CarrotRpc.configuration.bunny` can be set to custom
    [`Bunny` instance](http://www.rubydoc.info/gems/bunny/Bunny#new-class_method).
  * `CarrotRpc::RpcClient` and `CarrotRpc::RpcServer` subclasses can set their queue name with the `queue_name` class
    method. (It can be retrieved with `get_queue_name`.
  * `carrot_rpc`'s `--autoload_rails` boolean flag determines whether to load Rails environment.  The Rails path is
    assumed to the be the current working directory.
  * If a `CarrotRpc::RpcServer` method invoked from a JSON RPC `:method` raises an `CarrotRpc::Error`, then that error
    is converted to a JSON RPC error and sent back to the client.

### Bug Fixes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [shamil614](https://github.com/shamil614)
  * Send `jsonrpc` key instead of incorrect `json_rpc` key in JSON RPC response messages
  * All files under `bin` are marked as gem executables instead of just `carrot_rpc`
  * Fix files not loading properly when using `carrot_rpc`
  * Fix bug in logger file setup
  * The logger for each `CarrotRpc::RpcServer` is set before the server is started in
    `CarrotRpc::ServerRunner#run_servers` to prevent a race condition where `#start` may try to use the logger.

### Incompatible Changes
* [#1](https://github.com/C-S-D/carrot_rpc/pull/1) - [shamil614](https://github.com/shamil614)
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
