require 'base64'

module RProxy
  class HttpProxyParser

    def initialize(redis)
      @redis = redis
      @max_connection_size = 4 * 1024
    end

    def parse(data, need_auth)
      parse_connect_request(data)
      auth_user if need_auth

      [@schema.host, @schema.port]
    end

    private

    def auth_user
      temp = @header['proxy-authorization']
      pattern = /^Basic /
      token = temp.gsub(pattern, '')
      begin
        str = Base64.decode64(token)
        @username, @password = str.split(':')
      rescue
        raise RProxy::HTTPNotSupport, "token parse failed #{token}"
      end
      key = "proxy:#{@username}-#{@password}"
      value = @redis.get(key)

      raise RProxy::HTTPAuthFailed if value.nil?
      value
    end

    def parse_connect_request(data)
      size_of_data = data.bytesize
      raise RProxy::HTTPNotSupport unless
        size_of_data <= @max_connection_size && check_is_valid_request(data[0...8])
      temp = data.split("\r\n")
      @schema = parse_connect_target(temp.shift)
      @headers = parse_header(temp)
    end

    def parse_header(arr)
      header = {}
      arr.each do |val|
        name, value = val.split(':')
        next if name.nil?
        header[name.strip.downcase] = value&.strip
      end
      header
    end

    def parse_connect_target(data)
      temp = data.split("\s")
      URI("tcp://#{temp[1]}/")
    end

    def check_is_valid_request(s)
      # hold for heath check, if needed.
      # s[0...4] == "GET\s"
      s == RProxy::Constants::HTTP_CONNECT_TITLE
    end
  end
end