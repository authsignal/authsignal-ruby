# frozen_string_literal: true

module Authsignal
  module Middleware
    class JsonRequest < Faraday::Middleware
      def on_request(env)
        return if env.body.nil?

        parsed_body = JSON.parse(env.body)
        if parsed_body.is_a?(Hash)
          env.body = camelcase_keys(parsed_body).to_json
        end
      rescue JSON::ParserError
        # noop
      end

      private

      def camelcase_keys(hash)
        hash.transform_keys { |key| snake_to_camel(key.to_s).to_sym }
      end

      def snake_to_camel(str)
        str.split('_').inject([]) do |buffer, e|
          buffer.push(buffer.empty? ? e : e.capitalize)
        end.join
      end
    end
  end
end
