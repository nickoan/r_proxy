module RProxy
  class UsageManager
    def initialize(config, cache_pool, redis)
      @enable_cache = config.enable_cache
      @cache_pool = cache_pool
      @redis = redis
      @no_cache_below = config.no_cache_below
    end

    def auth_user(user, pass)
      key = proxy_key(user, pass)

      value = fetch_usage(key)

      return value if !value.nil? && value.to_i > 0
      nil
    end

    def report_usage(user, pass, value)
      return if user.nil? || pass.nil? || value.nil?

      key = proxy_key(user, pass)
      cache = @cache_pool[key]

      if cache.nil? || !@cache_pool.writable?
        @redis.decrby(key, value)
      else
        tmp = cache[:used]
        @cache_pool[key][:used] = tmp + value
      end
    end

    private

    def fetch_usage(key)
      return @redis.get(key) if !@enable_cache || !@cache_pool.writable?

      cache = @cache_pool[key]

      if cache.nil?
        value = @redis.get(key)

        return value if !value.nil? && value.to_i <= @no_cache_below

        @cache_pool[key] = {
          usage: value,
          used: 0
        }
        return value
      end

      cache[:usage]
    end

    def proxy_key(user, pass)
      "proxy:#{user}-#{pass}"
    end
  end
end