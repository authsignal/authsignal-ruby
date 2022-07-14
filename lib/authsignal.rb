require "httparty"

require "authsignal/client"
require "authsignal/configuration"

module Authsignal
    class << self
        attr_writer :configuration

        def setup
            yield(configuration)
        end

        def configuration
            @configuration ||= Authsignal::Configuration.new
        end


        def default_configuration
            configuration.defaults
        end

        def get_user(user_id)
            response = Client.new.get_user(user_id)
        end

        def get_action(user_id:, action_code:, idempotency_key:)
            response = Client.new.get_action(user_id, action_code, idempotency_key)
        end

        def identify(user_id:, user:)
            response = Client.new.identify(user_id, user)
        end

        def track_action(event, options={})
            raise ArgumentError, "Action Code is required" unless event[:actionCode].to_s.length > 0
            raise ArgumentError, "User ID value" unless event[:userId].to_s.length > 0

            response = Client.new.track(event, options)
            success = response && response.success? # HTTParty doesn't like `.try`
            if success
                puts("Tracked event! #{response.response.inspect}")
            else
                puts("Track failure! #{response.response.inspect} #{response.body}")
            end
            response
        rescue => e
            RuntimeError.new("Failed to track action")
            false
        end
    end
end
