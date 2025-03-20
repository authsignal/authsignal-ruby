RSpec.describe Authsignal do
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

  describe "user operations" do
    let(:user_id) { SecureRandom.uuid }

    it "manages the full user lifecycle" do
      # Enroll user
      enroll_response = described_class.enroll_verified_authenticator(
        user_id: user_id,
        attributes: {
          verification_method: "SMS",
          phone_number: "+6427000000"
        }
      )
      expect(enroll_response).not_to be_nil

      # Get user
      user_response = described_class.get_user(user_id: user_id)
      expect(user_response).not_to be_nil
      expect(user_response[:is_enrolled]).to be true
      expect(user_response[:email]).to be_nil

      # Update user
      update_response = described_class.update_user(
        user_id: user_id,
        attributes: {
          email: "test@example.com",
          phone_number: "+6427123456",
          username: "test@example.com",
          display_name: "Test User",
          custom: { foo: "bar" }
        }
      )

      expect(update_response[:email]).to eq("test@example.com")
      expect(update_response[:phone_number]).to eq("+6427123456")
      expect(update_response[:username]).to eq("test@example.com")
      expect(update_response[:display_name]).to eq("Test User")
      expect(update_response[:custom][:foo]).to eq("bar")

      # Delete user
      delete_response = described_class.delete_user(user_id: user_id)
      expect(delete_response[:success]).to be true

      # Verify deletion
      deleted_user = described_class.get_user(user_id: user_id)
      expect(deleted_user[:is_enrolled]).to be false
    end
  end

  describe "action operations" do
    let(:user_id) { SecureRandom.uuid }
    let(:action) { "Login" }

    it "manages action lifecycle" do
      # Track action
      track_response = described_class.track(
        user_id: user_id,
        action: action,
        attributes: { idempotency_key: SecureRandom.uuid }
      )
      expect(track_response).not_to be_nil
      expect(track_response[:state]).to eq("CHALLENGE_REQUIRED")

      # Validate challenge
      validate_response = described_class.validate_challenge(
        token: track_response[:token],
        user_id: user_id,
        action: action
      )
      expect(validate_response[:action]).to eq(action)
      expect(validate_response[:user_id]).to eq(user_id)
      expect(validate_response[:state]).to eq("CHALLENGE_REQUIRED")
      expect(validate_response[:is_valid]).to be false

      # Update action
      update_response = described_class.update_action(
        user_id: user_id,
        action: action,
        idempotency_key: track_response[:idempotency_key],
        attributes: { state: "REVIEW_REQUIRED" }
      )
      expect(update_response[:state]).to eq("REVIEW_REQUIRED")

      # Get action
      action_response = described_class.get_action(
        user_id: user_id,
        action: action, 
        idempotency_key: track_response[:idempotency_key]
      ) 
      expect(action_response[:state]).to eq("REVIEW_REQUIRED")
    end
  end
end
