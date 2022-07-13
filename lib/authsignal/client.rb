module Authsignal
    class Client
        USER_AGENT = "Authsignal Ruby v#{Authsignal::VERSION}"
        NO_API_KEY_MESSAGE  = "No Authsignal API Secret Key Set"
        include HTTParty

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
            actionCode = action[:actionCode]
            idempotencyKey = ERB::Util.url_encode(action[:idempotencyKey])
            userId = ERB::Util.url_encode(action[:userId])
            body = action.except(:userId, :actionCode)
            path = "/users/#{userId}/actions/#{actionCode}"
            puts path
            puts body
            post(path, query: options, body: JSON.generate(body))
        end

        def get_user(user_id)
            get("/users/#{ERB::Util.url_encode(user_id)}")
        end

        def get_action(user_id, action_code, idempotency_key)
            get("/users/#{ERB::Util.url_encode(user_id)}/actions/#{action_code}/#{ERB::Util.url_encode(idempotency_key)}")
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
