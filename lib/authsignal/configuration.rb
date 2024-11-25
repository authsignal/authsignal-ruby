require "ostruct"

module Authsignal
  class Configuration
        def self.config_option(name)
            define_method(name) do
                read_value(name)
            end

            define_method("#{name}=") do |value|
                set_value(name, value)
            end
        end
  
        config_option :api_secret_key
        config_option :api_url
        config_option :debug
        config_option :retry

        def initialize
            @config_values = {}
      
            # set default attribute values
            @defaults = OpenStruct.new({
                api_url: 'https://signal.authsignal.com/v1/',
                retry: false,
                debug: false
            })
        end

        def [](key)
            read_value(key)
        end
    
        def []=(key, value)
            set_value(key, value)
        end

        private
        def read_value(name)
            if @config_values.has_key?(name)
                @config_values[name]
            else
                @defaults.send(name)
            end
        end

        def set_value(name, value)
            @config_values[name] = value
        end
  end    
end
