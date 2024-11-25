require "faraday"
require "faraday/retry"
require "authsignal/version"
require "authsignal/client"
require "authsignal/configuration"
require "authsignal/api_error"
require "authsignal/middleware/json_response"
require "authsignal/middleware/json_request"

module Authsignal
    NON_API_METHODS = [:setup, :configuration, :default_configuration]

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

        def get_user(user_id:)
            response = Client.new.get_user(user_id: user_id)

            handle_response(response)
        end

        def update_user(user_id:, attributes:)
            response = Client.new.update_user(user_id: user_id, attributes: attributes)

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

        def update_action_state(user_id:, action:, idempotency_key:, state:)
            # NOTE: Rely on API to respond when given invalid state
            response = Client.new.update_action_state(user_id: user_id, action: action, idempotency_key: idempotency_key, state: state)

            handle_response(response)
        end

        def enroll_verified_authenticator(user_id:, attributes:)
            response = Client.new.enroll_verified_authenticator(user_id: user_id, attributes: attributes)

            handle_response(response)
        end

        def delete_authenticator(user_id:, user_authenticator_id:)
            response = Client.new.delete_authenticator(user_id: user_id, user_authenticator_id: user_authenticator_id)

            handle_response(response)
        end

        def track(:user_id, :action, :attributes)
            response = Client.new.track(user_id: user_id, action: action, attributes: attributes)
            handle_response(response)
        end

        def validate_challenge(token:, user_id: nil, action: nil)
            response = Client.new.validate_challenge(token: token,user_id: user_id, action: action)
            
            handle_response(response)
        end

        private

        def handle_response(response)
            if response.success?
                handle_success_response(response)
            else
                handle_error_response(response)
            end
        end

        def handle_success_response(response)
            response.body.merge(success?: true)
        end

        def handle_error_response(response)
            case response.body
            when Hash
                { status_code: response.status, success?: false, error_code: response.body[:error], error_description: response.body[:error_description] }
            else
                { status_code: response&.status || 500, success?: false }
            end
        end
    end

    methods = Authsignal.singleton_class.public_instance_methods(false)
    (methods - NON_API_METHODS).each do |method|
        define_singleton_method("#{method}!") do |*args, **kwargs|
            send(method, *args, **kwargs).tap do |response|
                status_code = response[:status_code]
                error_code = response[:error_code]
                error_description = response[:error_description]

                raise ApiError.new(status_code, error_code, error_description) unless response[:success?]
            end
        end
    end
end
