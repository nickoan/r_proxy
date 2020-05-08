module RProxy
  class UnbindService

    def initialize(config, redis)
      @config = config
      @cb_url = config.callback_url
      @redis = redis
      @usage_threshold = @config.usage_threshold
      @snapshot_expire_in = 15 * 60 # 15 min
    end

    def call(user, pass, usage)

      return if user.nil? || pass.nil? || usage.nil?

      key = proxy_key(user, pass)
      @redis.decrby(key, usage)
    end

    def proxy_key(user, pass)
      "proxy:#{user}-#{pass}"
    end
  end
end