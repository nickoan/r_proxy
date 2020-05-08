module RProxy
  class CallbackConnection < EM::Connection
    def initialize(uri, user, pass, value, tls)
      @uri = uri
      @path = uri.path.empty? ? '/' : uri.path
      @http_request = RProxy::HttpPostTemplate.
        new(@path).
        create(user, pass, value)
      @response = ''
      @need_tls = tls
    end

    def assign_logger(logger)
      @logger = logger
    end

    def connection_completed
      start_tls if @need_tls
      set_comm_inactivity_timeout(20)
      send_data(@http_request)
    end

    def receive_data(data)
      @response = data.split("\r\n")[0]
      close_connection
    end

    def ssl_handshake_completed
      send_data(@http_request)
    end

    def unbind
      @logger.info("#{@uri.host}#{@path} response status: #{@response}") if @logger
    end
  end
end