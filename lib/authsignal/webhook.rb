# frozen_string_literal: true

require 'openssl'
require 'json'
require 'base64'

module Authsignal
  DEFAULT_TOLERANCE = 5

  class Webhook
    VERSION = 'v2'

    attr_reader :api_secret_key

    def initialize(api_secret_key)
      @api_secret_key = api_secret_key
    end

    def construct_event(payload, signature, tolerance = DEFAULT_TOLERANCE)
      parsed_signature = parse_signature(signature)

      seconds_since_epoch = Time.now.to_i

      if tolerance.positive? && parsed_signature[:timestamp] < seconds_since_epoch - (tolerance * 60)
        raise InvalidSignatureError, 'Timestamp is outside the tolerance zone.'
      end

      hmac_content = "#{parsed_signature[:timestamp]}.#{payload}"

      computed_signature = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha256'),
        @api_secret_key,
        hmac_content
      )
      computed_signature_base64 = Base64.strict_encode64(computed_signature).delete('=')

      match = false

      parsed_signature[:signatures].each do |sig|
        if sig == computed_signature_base64
          match = true
          break
        end
      end

      raise InvalidSignatureError, 'Signature mismatch.' unless match

      JSON.parse(payload, symbolize_names: true)
    end

    def parse_signature(value)
      handle_invalid_signature unless value

      result = extract_signature_parts(value)
      handle_invalid_signature if result[:timestamp] == -1 || result[:signatures].empty?

      result
    end

    def extract_signature_parts(value)
      result = { timestamp: -1, signatures: [] }

      value.split(',').each do |item|
        key, val = item.split('=')
        next unless key && val

        result[:timestamp] = val.to_i if key == 't'
        result[:signatures] << val if key == VERSION
      end

      result
    end

    private

    def handle_invalid_signature
      raise InvalidSignatureError, 'Signature format is invalid.'
    end
  end
end
