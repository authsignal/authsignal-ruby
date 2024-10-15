# frozen_string_literal: true

module Authsignal
  module Middleware
    class JsonResponse < Faraday::Middleware
      def on_complete(env)
        ##
        # NOTE: Response header has "content-type: text/plain" atm
        # Otherwise, we can safe guard with: env.response_headers['content-type'] =~ /application\/json/
        parsed_body = JSON.parse(env.body)
        if parsed_body.is_a?(Hash)
          parsed_body.delete("actionCode") # Remove deprecated actionCode from response
          env.body = transform_to_snake_case(parsed_body)
        end
      rescue JSON::ParserError
        # noop
      end

      private

      def underscore(camelcased)
        return camelcased.to_s unless /[A-Z-]|::/.match?(camelcased)
        word = camelcased.to_s.gsub("::", "/")
        word.gsub!(/([A-Z])(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { ($1 || $2) << "_" }
        word.tr!("-", "_")
        word.downcase!
        word
      end

      def transform_to_snake_case(value)
        case value
        when Array
          value.map { |v| transform_to_snake_case(v) }
        when Hash
          value.transform_keys! { |k| underscore(k).to_sym }
          value.each do |key, val|
            value[key] = transform_to_snake_case(val)
          end
        else
          value
        end
      end
    end
  end
end
