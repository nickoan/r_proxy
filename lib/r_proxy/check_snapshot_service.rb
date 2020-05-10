module RProxy
  class CheckSnapshotService

    def initialize(redis, config)
      @redis = redis
      @snapshot_expire_in = 15 * 60
      @usage_threshold = config.usage_threshold
      @cb_url = config.callback_url
      @logger = config.logger
    end

    def call(user, pass, result)

      return if user.nil? ||  pass.nil? || result.nil?

      s_key = "proxy:#{user}-#{pass}:snapshot"
      snapshot_value = @redis.get(s_key)

      if snapshot_value.nil? || snapshot_value.empty?
        @redis.setex(s_key, @snapshot_expire_in, result)
      else
        tmp = snapshot_value.to_i - result.to_i

        if tmp >= @usage_threshold
          begin
            connection = RProxy::CallbackService.call(@cb_url, user, pass, tmp)
            connection.assign_logger(@logger)
            @redis.setex(s_key, @snapshot_expire_in, result)
          rescue => e
            @logger.error("callback service: @id:#{s_key}, #{e.message}") if @logger
          end
        end
      end
    end
  end
end