require 'erb'

module Authsignal
    class Client
        USER_AGENT = "Authsignal Ruby v#{Authsignal::VERSION}"
        NO_API_KEY_MESSAGE  = "No Authsignal API Secret Key Set"

        RETRY_OPTIONS = {
          max: 3,
          interval: 0.1,
          interval_randomness: 0.5,
          backoff_factor: 2,
        }.freeze
        private_constant :RETRY_OPTIONS

        def initialize(retry_options: RETRY_OPTIONS)
            @api_key = require_api_key

            @client = Faraday.new do |builder|
                builder.url_prefix = Authsignal.configuration.base_uri
                builder.adapter :net_http
                builder.request :authorization, :basic, @api_key, nil

                builder.headers['Accept'] = 'application/json'
                builder.headers['Content-Type'] = 'application/json'
                builder.headers['User-Agent'] = USER_AGENT

                builder.request :json
                builder.response :json, parser_options: { symbolize_names: true }

                builder.use Middleware::JsonRequest
                builder.use Middleware::JsonResponse

                builder.request :retry, retry_options if Authsignal.configuration.retry
                builder.response :logger, ::Logger.new(STDOUT), bodies: true if Authsignal.configuration.debug
            end
        end

        def track(event)
            user_id = url_encode(event[:user_id])
            action = event[:action]

            path = "users/#{user_id}/actions/#{action}"
            body = event.except(:user_id)

            make_request(:post, path, body: body)
        end

        def get_user(user_id:, redirect_url: nil)
            if(redirect_url)
                path = "users/#{url_encode(user_id)}?redirectUrl=#{redirect_url}"
            else
                path = "users/#{url_encode(user_id)}"
            end
            make_request(:get, path)
        end

        def update_user(user_id:, user:)
            make_request(:post, "users/#{url_encode(user_id)}", body: user)
        end

        def delete_user(user_id:)
            make_request(:delete, "users/#{url_encode(user_id)}")
        end

        def validate_challenge(user_id: nil, token:, action: nil)
            path = "validate"
            body = { user_id: user_id, token: token, action: action }
            body = remove_nil_values(body)

            make_request(:post, path, body: body)
        end

        def get_action(user_id, action, idempotency_key)
            make_request(:get, "users/#{url_encode(user_id)}/actions/#{action}/#{url_encode(idempotency_key)}")
        end

        ##
        # TODO: delete identify?
        def identify(user_id, user_payload)
            make_request(:post , "users/#{url_encode(user_id)}", body: user_payload)
        end

        def enroll_verified_authenticator(user_id, authenticator)
            make_request(:post, "users/#{url_encode(user_id)}/authenticators", body: authenticator)
        end

        def delete_user_authenticator(user_id:, user_authenticator_id:)
            make_request(:delete, "users/#{url_encode(user_id)}/authenticators/#{url_encode(user_authenticator_id)}")
        end

        private

        def remove_nil_values(hash)
            hash.reject { |_, value| value.nil? }
        end

        def make_request(method, path, body: nil, headers: nil)
            @client.public_send(method, path, body, headers)
        end

        def url_encode(s)
            ERB::Util.url_encode(s)
        end

        def version
            Authsignal.configuration.version
        end

        def print_api_key_warning
            $stderr.puts(NO_API_KEY_MESSAGE)
        end

        def require_api_key
            Authsignal.configuration.api_secret_key || print_api_key_warning
        end
    end
end
