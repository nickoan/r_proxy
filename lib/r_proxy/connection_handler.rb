module RProxy
  class ConnectionHandler < EM::Connection
    def initialize(config)
      @config = config
      @logger = @config.logger
      @redis = RProxy::RedisService.instance(@config.redis_url)
      @http_parser = HttpProxyParser.new(@redis)
      @disable_auth = @config.disable_auth
    end

    def post_init
      begin
        if @config.enable_ssl?
          start_tls(
            private_key_file: @config.ssl_private_key,
            cert_chain_file: @config.ssl_cert
          )
        end
        @port, @ip = Socket.unpack_sockaddr_in(get_peername)

        @timer = EventMachine.add_timer(20) do
          self.close_connection(false)
          @timer = nil
        end
      rescue => e
        if @logger
          @logger.error("id:#{@ip}, #{e.message}")
        end
        close_connection
      end
    end

    def receive_data(data)
      begin
        target_host, target_port = @http_parser.parse(data, !@disable_auth)

        # TODO add target connection

      rescue RProxy::HTTPAuthFailed
        send_data(RProxy::Constants::HTTP_FAILED_AUTH)
        close_connection_after_writing
      rescue RProxy::HTTPNotSupport
        send_data(RProxy::Constants::HTTP_BAD_REQUEST)
        close_connection_after_writing
      end
    end

    def proxy_target_unbound
      close_connection
    end
  end
end