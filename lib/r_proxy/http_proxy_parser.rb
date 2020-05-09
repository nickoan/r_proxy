require 'base64'

module RProxy
  class HttpProxyParser

    attr_reader :username, :password

    def initialize(usage_manager)
      @usage_manager = usage_manager
      @max_connection_size = 4 * 1024
    end

    def parse(data, need_auth)
      parse_connect_request(data)
      remain = 0
      remain = auth_user if need_auth

      [@schema.host, @schema.port, remain]
    end

    private

    def auth_user
      begin
        temp = @headers['proxy-authorization']
        raise RProxy::HTTPNotSupport if temp.nil?
        pattern = /^Basic /
        token = temp.gsub(pattern, '')
        str = Base64.decode64(token)
        @username, @password = str.split(':')
      rescue
        raise RProxy::HTTPNotSupport, "token parse failed #{token}"
      end

      auth_result = @usage_manager.auth_user(@username, @password)
      raise RProxy::HTTPAuthFailed if auth_result.nil?
      auth_result
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
      headers = {}
      arr.each do |val|
        name, value = val.split(':')
        next if name.nil?
        headers[name.strip.downcase] = value&.strip
      end
      headers
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