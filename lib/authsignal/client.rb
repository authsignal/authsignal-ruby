# frozen_string_literal: true

require 'erb'

module Authsignal
  class Client
    USER_AGENT = 'authsignal-ruby'
    NO_API_KEY_MESSAGE = 'No Authsignal API Secret Key Set'

    RETRY_OPTIONS = {
      max: 3,
      interval: 0.1,
      interval_randomness: 0.5,
      backoff_factor: 2
    }.freeze
    private_constant :RETRY_OPTIONS

    def initialize(retry_options: RETRY_OPTIONS)
      @api_key = require_api_key

      @client = Faraday.new do |builder|
        builder.url_prefix = Authsignal.configuration.api_url
        builder.adapter :net_http
        builder.request :authorization, :basic, @api_key, nil

        builder.headers['Accept'] = 'application/json'
        builder.headers['Content-Type'] = 'application/json'
        builder.headers['User-Agent'] = USER_AGENT
        builder.headers['X-Authsignal-Version'] = Authsignal::VERSION

        builder.request :json
        builder.response :json, parser_options: { symbolize_names: true }

        builder.use Middleware::JsonRequest
        builder.use Middleware::JsonResponse

        builder.request :retry, retry_options if Authsignal.configuration.retry
        builder.response :logger, ::Logger.new($stdout), bodies: true if Authsignal.configuration.debug
      end
    end

    def get_user(user_id:)
      path = "users/#{url_encode(user_id)}"
      make_request(:get, path)
    end

    def update_user(user_id:, attributes:)
      make_request(:post, "users/#{url_encode(user_id)}", body: attributes)
    end

    def delete_user(user_id:)
      make_request(:delete, "users/#{url_encode(user_id)}")
    end

    def get_authenticators(user_id:)
      make_request(:get, "users/#{url_encode(user_id)}/authenticators")
    end

    def enroll_verified_authenticator(user_id:, attributes:)
      make_request(:post, "users/#{url_encode(user_id)}/authenticators", body: attributes)
    end

    def delete_authenticator(user_id:, user_authenticator_id:)
      make_request(:delete, "users/#{url_encode(user_id)}/authenticators/#{url_encode(user_authenticator_id)}")
    end

    def track(user_id:, action:, attributes:)
      path = "users/#{user_id}/actions/#{action}"

      make_request(:post, path, body: attributes)
    end

    def validate_challenge(token:, user_id: nil, action: nil)
      path = 'validate'
      body = { user_id: user_id, token: token, action: action }

      make_request(:post, path, body: body)
    end

    def get_action(user_id:, action:, idempotency_key:)
      make_request(:get, "users/#{url_encode(user_id)}/actions/#{action}/#{url_encode(idempotency_key)}")
    end

    def update_action(user_id:, action:, idempotency_key:, attributes:)
      make_request(:patch, "users/#{url_encode(user_id)}/actions/#{action}/#{url_encode(idempotency_key)}", body: attributes)
    end

    def challenge(
      verification_method:,
      action:,
      idempotency_key: nil,
      user_id: nil,
      email: nil,
      phone_number: nil,
      sms_channel: nil,
      locale: nil,
      device_id: nil,
      ip_address: nil,
      user_agent: nil,
      custom: nil,
      scope: nil
    )
      body = {
        verification_method: verification_method,
        action: action,
        idempotency_key: idempotency_key,
        user_id: user_id,
        email: email,
        phone_number: phone_number,
        sms_channel: sms_channel,
        locale: locale,
        device_id: device_id,
        ip_address: ip_address,
        user_agent: user_agent,
        custom: custom,
        scope: scope
      }
      make_request(:post, 'challenge', body: body)
    end

    def verify(challenge_id:, verification_code:)
      body = {
        challenge_id: challenge_id,
        verification_code: verification_code
      }
      make_request(:post, 'verify', body: body)
    end

    def claim_challenge(
      challenge_id:,
      user_id:,
      skip_verification_check: nil,
      device_id: nil,
      ip_address: nil,
      user_agent: nil,
      custom: nil
    )
      body = {
        challenge_id: challenge_id,
        user_id: user_id,
        skip_verification_check: skip_verification_check,
        device_id: device_id,
        ip_address: ip_address,
        user_agent: user_agent,
        custom: custom
      }
      make_request(:post, 'claim', body: body)
    end

    def get_challenge(
      challenge_id: nil,
      user_id: nil,
      action: nil,
      verification_method: nil
    )
      params = {}
      params[:challengeId] = challenge_id if challenge_id
      params[:userId] = user_id if user_id
      params[:action] = action if action
      params[:verificationMethod] = verification_method if verification_method

      query_string = URI.encode_www_form(params) unless params.empty?
      path = query_string ? "challenges?#{query_string}" : 'challenges'

      make_request(:get, path)
    end

    ##
    # TODO: delete identify?
    def identify(user_id, user_payload)
      make_request(:post, "users/#{url_encode(user_id)}", body: user_payload)
    end

    private

    def url_encode(str)
      ERB::Util.url_encode(str)
    end

    def version
      Authsignal.configuration.version
    end

    def print_api_key_warning
      warn(NO_API_KEY_MESSAGE)
    end

    def require_api_key
      Authsignal.configuration.api_secret_key || print_api_key_warning
    end

    def make_request(method, path, body: nil, headers: nil)
      body = body.compact if body.is_a?(Hash)
      @client.public_send(method, path, body, headers)
    end
  end
end
