# frozen_string_literal: true

module Authsignal
  class ApiError < StandardError
    attr_reader :status_code, :error_code, :error_description

    def initialize(status_code, error_code, error_description = nil)
      message = format_message(status_code, error_code, error_description)

      super(message)

      @status_code = status_code
      @error_code = error_code
      @error_description = error_description
    end

    def to_s
      "#{super} status_code: #{status_code}, error_code: #{error_code}, error_description: #{error_description}"
    end

    private

    def format_message(status_code, error_code, error_description)
      "AuthsignalError: #{status_code} - #{format_description(error_code, error_description)}"
    end

    def format_description(error_code, error_description)
      error_description && error_description.length > 0 ? error_description : error_code
    end
  end
end
