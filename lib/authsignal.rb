require "faraday"
require "faraday/retry"
require "authsignal/version"
require "authsignal/client"
require "authsignal/configuration"
require "authsignal/middleware/json_response"
require "authsignal/middleware/json_request"

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

            handle_response(response)
        end

        def update_user(user_id:, user:)
            response = Client.new.update_user(user_id: user_id, user: user)

            handle_response(response)
        end

        def delete_user(user_id:)
            response = Client.new.delete_user(user_id: user_id)

            handle_response(response)
        end

        def get_action(user_id:, action:, idempotency_key:)
            response = Client.new.get_action(user_id, action, idempotency_key)

            handle_response(response)
        end

        def enroll_verified_authenticator(user_id:, authenticator:)
            response = Client.new.enroll_verified_authenticator(user_id, authenticator)

            handle_response(response)
        end

        def delete_user_authenticator(user_id:, user_authenticator_id: )
            response = Client.new.delete_user_authenticator(user_id: user_id, user_authenticator_id: user_authenticator_id)

            handle_response(response)
        end

        def track(event, options={})
            raise ArgumentError, "Action Code is required" unless event[:action].to_s.length > 0
            raise ArgumentError, "User ID value" unless event[:user_id].to_s.length > 0

            response = Client.new.track(event)
            handle_response(response)
        end

        def validate_challenge(token:, user_id: nil)
            response = Client.new.validate_challenge(user_id: user_id, token: token)
            
            handle_response(response)
        end

        private

        def handle_response(response)
            if response.success?
                response.body
            else
                handle_error_response(response)
            end
        end

        def handle_error_response(response)
            case response.body
            when Hash
                response.body.merge({ status: response.status })
            else
                { status: response.status }
            end
        end
    end
end
