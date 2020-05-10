module RProxy
  class CallbackService
    def self.call(url, user, pass, value)
      return if url.nil? || url.empty?
      uri = URI(url)
      tls = uri.scheme == 'https'
      EventMachine.connect(
        uri.host,
        uri.port,
        RProxy::CallbackConnection,
        uri,
        user,
        pass,
        value,
        tls
      )
    end
  end
end