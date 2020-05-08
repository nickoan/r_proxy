# RProxy

ruby http proxy server, base on eventmachine

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'r_proxy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install r_proxy

## Usage

Http and Https proxy server

integrated with Redis, if you enable auth then you must provide redis url
to let server connect to redis.
e.g: `server.set(:callback_url,'http://127.0.0.1:1234')`

redis key rule: `proxy:username-password`
redis value rule: `integer string` e.g: `1234567`
the value describe how many bytes that user can use. `unit: bytes`

```ruby
require 'r_proxy'

server = RProxy::MasterProcess.new

server.set(:host, '127.0.0.1')
server.set(:port, 8080)

# if disable_auth is true
# then server will not auth user and password
# server.set(:disable_auth, true)

# if disable unbind cb, then it mean
# server will not decrby usage for user
# server.set(:disable_unbind_cb, true)

# default is true 
server.set(:enable_ssl, true) 

server.set(:callback_url,'http://127.0.0.1:1234')

server.set(:redis_url, "redis://@localhost:6379/1")

server.set(:ssl_private_key, './server_key.txt')
server.set(:ssl_cert, './server_cert.txt')

server.set(:logger, Logger.new(STDOUT))
# logger output like:
# I, [2020-05-08T21:04:00.492477 #86348]  INFO -- : r_proxy @1588935840 process start....
# I, [2020-05-08T21:04:21.534989 #87168]  INFO -- : r_proxy rebuild new instance replace @1588935861....

# call run to start server
server.run!
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/r_proxy.

