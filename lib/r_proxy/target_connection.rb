module RProxy
  class TargetConnection < EM::Connection

    def initialize(client, disable_cb, buffer_size, usage_manager)
      @disable_unbind_callback = disable_cb
      @client_connection = client
      @buffer_size = buffer_size
      @usage_manager = usage_manager
    end

    def assign_logger(logger)
      @logger = logger
    end

    def assign_user_and_password(username, password)
      @username = username
      @password = password
    end

    def connection_completed
      response_proxy_connect_ready
    end

    def proxy_target_unbound
      close_connection
    end

    def unbind
      return if @disable_unbind_callback
      @usage_manager.report_usage(@username, @password, get_proxied_bytes)
    end

    private

    def response_proxy_connect_ready
      begin
        @client_connection.send_data(RProxy::Constants::HTTP_SUCCESS)
        @client_connection.proxy_incoming_to(self, @buffer_size)
        proxy_incoming_to(@client_connection, @buffer_size)
      rescue => e
        port, ip = Socket.unpack_sockaddr_in(get_peername)
        @logger.error("target ip: #{ip}, port: #{port}, #{e.message}") if @logger
      end
    end
  end
end