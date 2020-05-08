require 'json'

module RProxy
  class HttpPostTemplate

    def initialize(route)
      @route = route
      @headers = init_headers
      @protocol = "POST #{route} HTTP/1.1"
    end

    def create(user, pass, value)
      body = {
        user: user,
        pass: pass,
        value: value,
        timestamp: Time.now.getutc.to_i
      }.to_json

      @headers['Content-Length'] = body.bytesize

      headers_str = header_to_s

      "#{@protocol}\r\n#{headers_str}\r\n#{body}"
    end

    private

    def header_to_s
      tmp = ''
      @headers.each do |k, v|
        tmp += "#{k}: #{v}\r\n"
      end
      tmp
    end

    def init_headers
      {
        'User-Agent' => "RSocks/#{RProxy::VERSION}",
        'Content-Type' => 'application/json',
      }
    end
  end
end