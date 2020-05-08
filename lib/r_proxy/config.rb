module RProxy
  class Config
    class << self
      def add_config(name, default_value = nil)
        self.define_method("#{name}") do
          store = instance_variable_get('@store')
          store["#{name}"].nil? ? default_value : store["#{name}"]
        end

        define_set_config_value_method(name)
      end

      def add_exception_config(name)
        self.define_method("#{name}") do
          store = instance_variable_get('@store')
          val = store["#{name}"]
          raise RProxy::EmptyConfigError,
                "#{name} cannot set as empty or nil" if val.nil?
          val
        end

        define_set_config_value_method(name)
      end

      def define_set_config_value_method(name)
        self.define_method("#{name}=") do |value|
          store = instance_variable_get('@store')
          store["#{name}"] = value
        end
      end
    end

    add_config(:instances, 1)
    add_config(:host, '0.0.0.0')
    add_config(:port, 8081)

    add_config(:logger)

    add_config(:callback_url)
    add_config(:usage_threshold, 1 * 1024 * 1024 * 1024)
    add_config(:proxy_buffer, 1024 * 1024 * 10) # default is 10M

    add_config(:disable_auth, false)
    add_config(:disable_unbind_cb, false)

    # e.g "redis://:p4ssw0rd@10.0.1.1:6380/15"
    add_exception_config(:redis_url)

    add_config(:enable_ssl, true)
    add_exception_config(:ssl_private_key)
    add_exception_config(:ssl_cert)

    def initialize
      @store = {}
    end
  end
end