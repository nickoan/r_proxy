require 'r_proxy'

server = RProxy::MasterProcess.new

server.set(:host, '127.0.0.1')
server.set(:port, 8080)


# server.set(:disable_auth, true)
# server.set(:disable_unbind_cb, true)
# server.set(:enable_ssl, false)

server.set(:callback_url,'http://127.0.0.1:1234')

server.set(:redis_url, "redis://@localhost:6379/1")

server.set(:ssl_private_key, './server_key.txt')
server.set(:ssl_cert, './server_cert.txt')

server.set(:logger, Logger.new('./debug.log'))
server.run!