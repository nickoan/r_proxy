module RProxy
  class ConnectionHandler < EM::Connection
    def initialize(config, cache_pool)
      @config = config
      @logger = @config.logger
      @redis = RProxy::RedisService.instance(@config.redis_url)
      @disable_auth = @config.disable_auth
      @disable_unbind_cb = @config.disable_unbind_cb
      @buffer_size = @config.proxy_buffer
      @callback_url = @config.callback_url
      @username = nil
      @password = nil
      @target_connection = nil
      @cache_pool = cache_pool
      @usage_manager = RProxy::UsageManager.new(config, @cache_pool, @redis)
      @http_parser = HttpProxyParser.new(@usage_manager)
      @enable_force_quit = config.enable_force_quit
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

        if @enable_force_quit
          @timer = EventMachine.add_timer(20) do
            self.close_connection(false)
            @timer = nil
          end
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
        target_host, target_port, _= @http_parser.parse(data, !@disable_auth)

        @target_connection = EventMachine.
          connect(target_host,
                  target_port,
                  RProxy::TargetConnection,
                  self,
                  @disable_unbind_cb,
                  @buffer_size,
                  @usage_manager)
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
          @logger.error("client: #{@ip}, target: #{target_host}, port: #{target_port}, #{e.message}")
        end
        close_connection
      end
    end

    def proxy_target_unbound
      close_connection
    end

    def unbind
      if @timer
        EventMachine.cancel_timer(@timer)
      end
      return if @disable_unbind_cb
      @usage_manager.report_usage(@username, @password, get_proxied_bytes)
    end
  end
end