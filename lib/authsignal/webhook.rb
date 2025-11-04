require 'openssl'
require 'json'
require 'base64'

module Authsignal
  # Default tolerance (in minutes) for difference between timestamp in signature and current time
  # This is used to prevent replay attacks
  DEFAULT_TOLERANCE = 5

  class Webhook
    VERSION = "v2"

    attr_reader :api_secret_key

    def initialize(api_secret_key)
      @api_secret_key = api_secret_key
    end

    def construct_event(payload, signature, tolerance = DEFAULT_TOLERANCE)
      parsed_signature = parse_signature(signature)

      seconds_since_epoch = Time.now.to_i

      if tolerance > 0 && parsed_signature[:timestamp] < seconds_since_epoch - (tolerance * 60)
        raise InvalidSignatureError, "Timestamp is outside the tolerance zone."
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

      unless match
        raise InvalidSignatureError, "Signature mismatch."
      end

      JSON.parse(payload, symbolize_names: true)
    end

    def parse_signature(value)
      result = {
        timestamp: -1,
        signatures: []
      }

      return handle_invalid_signature unless value

      value.split(',').each do |item|
        kv = item.split('=')
        next unless kv.length == 2

        if kv[0] == 't'
          result[:timestamp] = kv[1].to_i
        elsif kv[0] == VERSION
          result[:signatures] << kv[1]
        end
      end

      if result[:timestamp] == -1 || result[:signatures].empty?
        handle_invalid_signature
      end

      result
    end

    private

    def handle_invalid_signature
      raise InvalidSignatureError, "Signature format is invalid."
    end
  end
end
