module RProxy
  class RedisService
    def self.instance(url)
      Redis.new(url: url)
    end
  end
end