module RProxy
  class UnbindService

    def initialize(config, redis)
      @cb_url = config.callback_url
      @redis = redis
      @usage_threshold = @config.usage_threshold
      @snapshot_expire_in = 15 * 60 # 15 min
    end

    def call(user, pass, usage)

      return if user.nil? || pass.nil? || usage.nil?

      key = proxy_key(user, pass)
      result = @redis.decrby(key, usage)

      s_key = snapshot_key(user, pass)
      snapshot_value = @redis.get(s_key)

      if snapshot_value.nil? || snapshot_value.empty?
        @redis.setex(s_key, @snapshot_expire_in, result)
      else
        tmp = snapshot_value - result

        if tmp >= @usage_threshold
          RProxy::CallbackService.call(@cb_url, user, pass, tmp)
          @redis.setex(s_key, @snapshot_expire_in, result)
        end
      end
    end

    def proxy_key(user, pass)
      "proxy:#{user}-#{pass}"
    end

    def snapshot_key(user, pass)
      "#{proxy_key(user, pass)}:snapshot"
    end
  end
end