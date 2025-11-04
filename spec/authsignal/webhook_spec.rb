require 'json'

RSpec.describe Authsignal::Webhook do
  let(:api_url) { ENV['AUTHSIGNAL_API_URL'] }
  let(:api_secret_key) { ENV['AUTHSIGNAL_API_SECRET_KEY'] }

  before do
    raise "AUTHSIGNAL_API_URL is undefined in env" unless api_url
    raise "AUTHSIGNAL_API_SECRET_KEY is undefined in env" unless api_secret_key

    Authsignal.setup do |config|
      config.api_secret_key = api_secret_key
      config.api_url = api_url
    end
  end

  describe "webhook verification" do
    it "raises error for invalid signature format" do
      payload = JSON.generate({})
      signature = "123"

      expect {
        Authsignal.webhook.construct_event(payload, signature)
      }.to raise_error(Authsignal::InvalidSignatureError, "Signature format is invalid.")
    end

    it "raises error for timestamp outside tolerance zone" do
      payload = JSON.generate({})
      signature = "t=1630000000,v2=invalid_signature"

      expect {
        Authsignal.webhook.construct_event(payload, signature)
      }.to raise_error(Authsignal::InvalidSignatureError, "Timestamp is outside the tolerance zone.")
    end

    it "raises error for invalid computed signature" do
      payload = JSON.generate({})
      timestamp = Time.now.to_i
      signature = "t=#{timestamp},v2=invalid_signature"

      expect {
        Authsignal.webhook.construct_event(payload, signature)
      }.to raise_error(Authsignal::InvalidSignatureError, "Signature mismatch.")
    end

    it "validates a valid signature" do
      payload = JSON.generate({
        version: 1,
        id: "bc1598bc-e5d6-4c69-9afb-1a6fe3469d6e",
        source: "https://authsignal.com",
        time: "2025-02-20T01:51:56.070Z",
        tenantId: "7752d28e-e627-4b1b-bb81-b45d68d617bc",
        type: "email.created",
        data: {
          to: "user@example.com",
          code: "157743",
          userId: "b9f74d36-fcfc-4efc-87f1-3664ab5a7fb0",
          actionCode: "accountRecovery",
          idempotencyKey: "ba8c1a7c-775d-4dff-9abe-be798b7b8bb9",
          verificationMethod: "EMAIL_OTP"
        }
      })

      tolerance = -1

      signature = "t=1740016316,v2=89vWAaNuB+MoOqeOFdINSi6VRGlT1OkeJIi9PPZkk/8"

      event = Authsignal.webhook.construct_event(payload, signature, tolerance)

      expect(event).not_to be_nil
      expect(event[:version]).to eq(1)
      expect(event[:data][:actionCode]).to eq("accountRecovery")
    end

    it "validates a signature when 2 API keys are active" do
      payload = JSON.generate({
        version: 1,
        id: "af7be03c-ea8f-4739-b18e-8b48fcbe4e38",
        source: "https://authsignal.com",
        time: "2025-02-20T01:47:17.248Z",
        tenantId: "7752d28e-e627-4b1b-bb81-b45d68d617bc",
        type: "email.created",
        data: {
          to: "test@example.com",
          code: "718190",
          userId: "b9f74d36-fcfc-4efc-87f1-3664ab5a7fb0",
          actionCode: "accountRecovery",
          idempotencyKey: "68d68190-fac9-4e91-b277-c63d31d3c6b1",
          verificationMethod: "EMAIL_OTP"
        }
      })

      tolerance = -1

      signature = "t=1740016037,v2=t3QXS5VJp03g8Kuh8YoPOSg4hUOR/ChThUm3xd67AoI,v2=oldKeySignature123"

      event = Authsignal.webhook.construct_event(payload, signature, tolerance)

      expect(event).not_to be_nil
    end
  end
end
