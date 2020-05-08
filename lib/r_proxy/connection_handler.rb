module RProxy
  class ConnectionHandler < EM::Connection
    def initialize(config)
      @config = config
      @logger = @config.logger
      @redis = RProxy::RedisService.instance(@config.redis_url)
      @http_parser = HttpProxyParser.new(@redis)
      @disable_auth = @config.disable_auth
      @disable_unbind_cb = @config.disable_unbind_cb
      @buffer_size = @config.proxy_buffer
      @callback_url = @config.callback_url
      @username = nil
      @password = nil
      @target_connection = nil

      @unbind_service = UnbindService.new(config, @redis)
    end

    def post_init
      begin
        if @config.enable_ssl
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

        @target_connection = EventMachine.
          connect(target_host,
                  target_port,
                  RProxy::TargetConnection,
                  self,
                  @disable_unbind_cb,
                  @buffer_size,
                  @unbind_service)
        @target_connection.assign_logger(@logger)
        if !@disable_auth
          @username = @http_parser.username
          @password = @http_parser.password
          @target_connection.assign_user_and_password(@username, @password)
        end
      rescue RProxy::HTTPAuthFailed
        send_data(RProxy::Constants::HTTP_FAILED_AUTH)
        close_connection_after_writing
      rescue RProxy::HTTPNotSupport
        send_data(RProxy::Constants::HTTP_BAD_REQUEST)
        close_connection_after_writing
      rescue => e
        if @logger
          @logger.error("client: id:#{@ip}, #{e.message}")
        end
        close_connection
      end
    end

    def proxy_target_unbound
      close_connection
    end

    def unbind
      return if @disable_unbind_cb
      @unbind_service.call(@username, @password, get_proxied_bytes)
    end
  end
end