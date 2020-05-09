require 'r_proxy'

server = RProxy::MasterProcess.new

server.set(:host, '127.0.0.1')
server.set(:port, 8080)

server.set(:instances, 3)

#server.set(:disable_auth, true)
server.set(:disable_unbind_cb, false)
server.set(:enable_ssl, true)

server.set(:callback_url,'http://127.0.0.1:1234')

server.set(:no_cache_below, 1 * 1024 * 1024 * 1024)
server.set(:cache_clear_threshold, 1)
server.set(:enable_force_quit, true)

server.set(:redis_url, "redis://@localhost:6379/1")

server.set(:ssl_private_key, './server_key.txt')
server.set(:ssl_cert, './server_cert.txt')

server.set(:logger, Logger.new(STDOUT))
server.run!