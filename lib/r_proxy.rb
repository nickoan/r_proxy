require 'r_proxy/version'
require 'eventmachine'
require 'redis'
require 'r_proxy/config'
require 'r_proxy/constants'
require 'r_proxy/http_proxy_parser'
require 'r_proxy/redis_service'
require 'r_proxy/connection_handler'
require 'r_proxy/proxy_server'

module RProxy
  class Error < StandardError; end
  class EmptyConfigError < Error; end

  class HTTPNotSupport < Error; end
  class HTTPAuthFailed < Error; end
end
