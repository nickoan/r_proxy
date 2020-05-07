module RProxy
  class TargetConnection < EM::Connection

    def initialize(client, enable_cb, buffer_size)
      @enable_unbind_callback = enable_cb
      @client_connection = client
      @buffer_size = buffer_size
    end

    def assign_user_and_password(username, password)
      @username = username
      @password = password
    end

    def assign_redis(redis)
      @redis = redis
    end

    def connection_completed
      response_proxy_connect_ready
    end

    def proxy_target_unbound
      close_connection
    end

    def unbind
      return if @redis.nil?
      usage = get_proxied_bytes
      key = "proxy:#{@username}-#{@password}"
      left = @redis.decrby(key,usage)
      left
    end

    private

    def response_proxy_connect_ready
      @client_connection.send_data(RProxy::Constants::HTTP_SUCCESS)
      @client_connection.proxy_incoming_to(self, @buffer_size)
      proxy_incoming_to(@client_connection, @buffer_size)
    end
  end
end