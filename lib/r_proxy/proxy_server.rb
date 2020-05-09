module RProxy
  class ProxyServer
    def initialize(sock, config, instance_id)
      @sock = sock
      @config = config
      @cache_pool = RProxy::CachePool.new
      @logger = @config.logger
      @instance_id = instance_id
    end

    def run!
      Signal.trap("TERM") { exit! }
      EventMachine.run do

        if @config.enable_cache
          @period_timer = EventMachine.add_periodic_timer(30) do
            @cache_pool.disable_write!

            tmp = @cache_pool.flush

            report_and_clean_cache(tmp)

            @cache_pool.enable_write!
          end
        end

        EventMachine.attach_server(@sock, RProxy::ConnectionHandler, @config, @cache_pool)
      end
    end

    private

    def report_and_clean_cache(cache)
      return if cache.empty?

      redis = RProxy::RedisService.instance(@config.redis_url)
      time_start = (Time.now.to_f * 1000).floor
      cache.each do |k, value|
        used = value[:used]
        next if used.nil? || used.zero?
        redis.decrby(k, used)
      end
      time_end = (Time.now.to_f * 1000).floor
      spend = time_end - time_start

      if spend > @config.cache_clear_threshold
        @logger.info("@#{@instance_id} clear cache: #{spend} ms, remove: #{cache.size} items") if @logger
      end
    end
  end
end