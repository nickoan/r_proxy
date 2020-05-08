module RProxy
  class CallbackService
    def self.call(url, user, pass, value)
      uri = URI(url)
      tls = uri.scheme == 'https'
      path = uri.path.empty? ? '/' : uri.path
      EventMachine.connect(
        uri.host,
        uri.port,
        RProxy::CallbackConnection,
        path,
        user,
        pass,
        value,
        tls
      )
    end
  end
end