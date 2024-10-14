# frozen_string_literal: true

module Authsignal
  class ApiError < StandardError
    attr_reader :status, :error, :description

    def initialize(message = "An unexpected API error occurred", status, error, description)
      @status      = status || 500
      @error       = error
      @description = description

      super(message)
    end

    def to_s
      "#{super} status: #{status}, error: #{error}, description: #{description}"
    end
  end
end
