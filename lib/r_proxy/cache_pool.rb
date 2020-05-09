module RProxy
  class CachePool

    def initialize
      @pool = {}
      @able_write = true
    end

    def []=(key, value)
      return value if !@able_write
      @pool[key] = value
    end


    def [](key)
      @pool[key]
    end

    def writable?
      @able_write
    end

    def disable_write!
      @able_write = false
    end

    def enable_write!
      @able_write = true
    end

    def flush
      tmp = @pool
      @pool = {}
      tmp
    end
  end
end