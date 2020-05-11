module RProxy
  class CallbackConnection < EM::Connection
    def initialize(uri, user, pass, value, tls)
      @uri = uri
      @path = uri.path.empty? ? '/' : uri.path
      @http_request = RProxy::HttpPostTemplate.
        new(@uri, @path).create(user, pass, value)
      @response = ''
      @need_tls = tls
    end

    def assign_logger(logger)
      @logger = logger
    end

    def post_init
      start_tls if @need_tls
      set_comm_inactivity_timeout(20)
    end

    def ssl_handshake_completed
      send_data(@http_request)
    end

    def connection_completed
      send_data(@http_request) if !@need_tls
    end

    def receive_data(data)
      @response = data.split("\r\n")[0]
      close_connection
    end

    def unbind
      @logger.info("#{@uri.host}#{@path} response status: #{@response}") if @logger
    end
  end
end