require 'r_proxy/version'
require 'eventmachine'
require 'redis'

module RProxy
  class Error < StandardError; end
  class EmptyConfigError < Error; end
end
