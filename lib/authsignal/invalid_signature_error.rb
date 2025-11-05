module Authsignal
  class InvalidSignatureError < StandardError
    def initialize(message)
      super(message)
    end
  end
end
