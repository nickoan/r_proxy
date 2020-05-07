module RProxy
  class Config
    class << self
      def add_config(name, default_value = nil)
        self.define_method("#{name}") do
          store = instance_variable_get('@store')
          store["#{name}"] || default_value
        end

        self.define_method("#{name}=") do |value|
          store = instance_variable_get('@store')
          store["#{name}"] = value
        end
      end
    end

    def initialize
      @store = {}
    end
  end
end