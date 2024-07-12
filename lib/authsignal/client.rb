module Authsignal
    class Client
        USER_AGENT = "Authsignal Ruby v#{Authsignal::VERSION}"
        NO_API_KEY_MESSAGE  = "No Authsignal API Secret Key Set"
        include HTTParty

        def handle_response(response)
            unless response.success?
              raise HTTParty::ResponseError, "Failed with status code #{response.code}"
            end
            response
        end

        def initialize
            self.class.base_uri Authsignal.configuration.base_uri
            @api_key = require_api_key

            @headers = {
                        "User-Agent" => USER_AGENT,
                        'Content-Type' => 'application/json' 
                        }
        end

        def require_api_key
            Authsignal.configuration.api_secret_key || print_api_key_warning
        end

        def track(action, options = {})
            actionCode = action[:action]
            idempotencyKey = ERB::Util.url_encode(action[:idempotencyKey])
            userId = ERB::Util.url_encode(action[:userId])
            body = action.except(:userId, :actionCode)
            path = "/users/#{userId}/actions/#{actionCode}"

            post(path, query: options, body: JSON.generate(body))
        end

        def get_user(user_id:, redirect_url: nil)
            if(redirect_url)
                path = "/users/#{ERB::Util.url_encode(user_id)}?redirectUrl=#{redirect_url}"
            else
                path = "/users/#{ERB::Util.url_encode(user_id)}"
            end
            get(path)
        end

        def update_user(user_id:, user_payload)
            post("/users/#{ERB::Util.url_encode(user_id)}", body: JSON.generate(user_payload))
        end

        def validate_challenge(user_id: nil, token:)
            path = "/validate"

            response = post(path, query: {}, body: { userId: user_id, token: token }.to_json)

            handle_response(response)
        end

        def get_action(user_id, action, idempotency_key)
            get("/users/#{ERB::Util.url_encode(user_id)}/actions/#{action}/#{ERB::Util.url_encode(idempotency_key)}")
        end

        def identify(user_id, user_payload)
            post("/users/#{ERB::Util.url_encode(user_id)}", body: JSON.generate(user_payload))
        end

        def enroll_verified_authenticator(user_id, authenticator)
            post("/users/#{ERB::Util.url_encode(user_id)}/authenticators", body: JSON.generate(authenticator))
        end

        def get(path, query: {})
            self.class.get(path, headers: @headers, basic_auth: {username: @api_key})
        end

        def post(path, query: {}, body: {})
            self.class.post(path, headers: @headers, body: body, basic_auth: {username: @api_key})
        end

        private

        def version
            Authsignal.configuration.version
        end

        def print_api_key_warning
            $stderr.puts(NO_API_KEY_MESSAGE)
        end
    end
end
