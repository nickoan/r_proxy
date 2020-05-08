module RProxy
  class ProxyServer
    def initialize(sock, config)
      @sock = sock
      @config = config
    end

    def run!
      Signal.trap("TERM") { exit! }
      EventMachine.run do
        EventMachine.attach_server(server, RProxy::ConnectionHandler, @config)
      end
    end
  end
end