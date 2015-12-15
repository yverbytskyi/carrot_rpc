# CarrotRpc

An opinionated approach to doing Remote Procedure Call (RPC) with RabbitMQ and the bunny gem. CarrotRpc serves as a way to streamline the RPC workflow so developers can focus on the implementation and not the plumbing when working with RabbitMQ.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'carrot_rpc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install carrot_rpc

## Configuration
There's two modes for CarrotRpc: server and client. The server is run via command line, and the client is run in your ruby application during the request / response lifecycle (like your Rails Controller).
### Server
The server is configured via command line and run in it's own process.

Carrot is easy to run via command line: 
```bash
carrot_rpc
```
By typing in `carrot_rpc -h` you will see all the command line options:
```bash
Usage: server [options]

Process options:
    -d, --daemonize              run daemonized in the background (default: false)
        --pidfile PIDFILE        the pid filename
    -s, --runloop_sleep VALUE    Configurable sleep time in the runloop
        --autoload_rails VALUE   loads rails env by default. Uses Rails Logger by default.
        --logfile VALUE          relative path and name for Log file. Overrides Rails logger.
        --loglevel VALUE         levels of loggin: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
        --rabbitmq_url VALUE     connection string to RabbitMQ 'amqp://user:pass@host:10000/vhost'

Ruby options:
    -I, --include PATH           an additional $LOAD_PATH
        --debug                  set $DEBUG to true
        --warn                   enable warnings

Common options:
    -h, --help
    -v, --version
```


### Client
Clients are configured by initializing `CarrotRpc::Configuration`. The most common way in Rails is to setup an initializer in `/config/initializers/carrot_rpc.rb`

```ruby
CarrotRpc.configure do |config|
  # Required on the client to connect to RabbitMQ. 
  # Bunny defaults to connecting to ENV['RABBITMQ_URL']. See Bunny docs.
  config.bunny = Bunny.new.start
  # Set the log level. Ruby Logger Docs http://ruby-doc.org/stdlib-2.2.0/libdoc/logger/rdoc/Logger.html
  config.loglevel = Logger::Info
  # Create a new logger or use the Rails logger. 
  # When using Rails, use a tagged log to make it easier to track RPC.
  config.logger = CarrotRpc::TaggedLog.new(logger: Rails.logger, tags: ["Carrot RPC Client"])
  
  # Don't use. Server implementation only. The values below are set via CLI:
  # config.pidfile = nil
  # config.runloop_sleep = 0
  # config.logfile = nil
end
```

## Usage
### Writing Servers
Carrot CLI will look for your servers in `app/servers` directory. This directory should not be autoloaded by the host application. 

Example Server: `app/servers/car_server.rb`
```ruby
class CarServer < CarrotRpc::RpcServer
  def show(params)
    # ...do something
    Car.find(params[:id]).to_json
  end
end
```
The method can return any data that can be stringified. But CarrotRPC uses [JSON RPC 2.0](http://www.jsonrpc.org/specification) as protocol for the message workflow.
### Writing Clients
Clients are not run in the CLI, and are typlically invoked during a request / response lifecycle in a web application. In the case of Rails, Clients would most likely be used in a controller action. Clients should be written in the `app/clients` directory of the host application, and should be autoloaded by Rails.

Example Client: `app/clients/cars_client.rb`
```ruby
  class CarClient < CarrotRpc::RpcClient
    # By default RpcClient defines the following Railsy inspired methods:
    # def show(params)
    # def index(params)
    # def create(params)
    # def update(params)
    # You can easily add your own like so:
    def foo_method(params)
      remote_call('foo_method', params)
    end
  end
```

Example Rails Controller:
```ruby
class CarsController < ApplicationController
  def show
    car_client = CarClient.new
    car_client.start
    result = car_client.show({id: 1})
    # Good idea to clean up connections when finished.
    car_client.channel.close
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/carrot_rpc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
