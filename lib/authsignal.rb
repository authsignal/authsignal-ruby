require "httparty"

require "authsignal/version"
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

        def get_user(user_id:, redirect_url: nil)
            response = Client.new.get_user(user_id: user_id, redirect_url: redirect_url)
            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        end

        def update_user(user_id:, user:)
            response = Client.new.update_user(user_id: user_id, user: user)
            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        end

        def delete_user(user_id:)
            response = Client.new.delete_user(user_id: user_id)
            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        end

        def get_action(user_id:, action:, idempotency_key:)
            response = Client.new.get_action(user_id, action, idempotency_key)
            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        end

        def enroll_verified_authenticator(user_id:, authenticator:)
            authenticator = authenticator.transform_keys { |key| camelize(key) }
            response = Client.new.enroll_verified_authenticator(user_id, authenticator)
            
            if response["authenticator"]
                response["authenticator"] = response["authenticator"].transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
            end

            response = response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)

            response
        end

        def delete_user_authenticator(user_id:, user_authenticator_id: )
            response = Client.new.delete_user_authenticator(user_id: user_id, user_authenticator_id: user_authenticator_id)
            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        end

        def track(event, options={})
            raise ArgumentError, "Action Code is required" unless event[:action].to_s.length > 0
            raise ArgumentError, "User ID value" unless event[:user_id].to_s.length > 0

            event = event.transform_keys { |key| camelize(key) }

            response = Client.new.track(event, options)
            success = response && response.success?
            if success
                puts("Tracked event! #{response.response.inspect}")
            else
                puts("Track failure! #{response.response.inspect} #{response.body}")
            end

            response.transform_keys { |key| underscore(key) }.transform_keys(&:to_sym)
        rescue => e
            RuntimeError.new("Failed to track action")
            false
        end

        def validate_challenge(token:, user_id: nil)
            response = Client.new.validate_challenge(user_id: user_id, token: token)
            
            return { user_id: response["userId"], is_valid: response["isValid"], state: response["state"], action: response["actionCode"] }
        end

        private
        def underscore(string)
            string.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr("-", "_").
            downcase
        end

        def camelize(symbol)
            string = symbol.to_s
            string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
            string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::").to_sym
        end
    end
end
