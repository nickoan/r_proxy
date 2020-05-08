require 'r_proxy/version'
require 'eventmachine'
require 'redis'
require 'r_proxy/config'
require 'r_proxy/constants'
require 'r_proxy/http_proxy_parser'
require 'r_proxy/redis_service'

require 'r_proxy/master_process'
require 'r_proxy/process_handler'

require 'r_proxy/target_connection'
require 'r_proxy/connection_handler'
require 'r_proxy/unbind_service'

require 'r_proxy/callback_connection'
require 'r_proxy/http_post_template'
require 'r_proxy/callback_service'

require 'r_proxy/proxy_server'
require 'r_proxy/master_process'

module RProxy
  class Error < StandardError; end
  class EmptyConfigError < Error; end

  class HTTPNotSupport < Error; end
  class HTTPAuthFailed < Error; end
end
