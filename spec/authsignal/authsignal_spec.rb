require 'securerandom'

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

  it "user tests" do
    user_id = SecureRandom.uuid

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

    # Update user with all attributes
    email = "test@example.com"
    phone_number = "+6427123456"
    username = email
    display_name = "Test User"
    custom = { foo: "bar" }

    update_response = described_class.update_user(
        user_id: user_id,
      attributes: {
        email: email,
        phone_number: phone_number,
        username: username,
        display_name: display_name,
        custom: custom
      }
    )

    expect(update_response).not_to be_nil
    expect(update_response[:email]).to eq(email)
    expect(update_response[:phone_number]).to eq(phone_number)
    expect(update_response[:username]).to eq(username)
    expect(update_response[:display_name]).to eq(display_name)
    expect(update_response[:custom][:foo]).to eq("bar")

    # Delete user
    described_class.delete_user(user_id: user_id)

    # Verify deletion
    deleted_user_response = described_class.get_user(user_id: user_id)
    expect(deleted_user_response[:is_enrolled]).to be false
  end

  it "authenticator tests" do
    user_id = SecureRandom.uuid

    # Enroll authenticator
    enroll_response = described_class.enroll_verified_authenticator(
      user_id: user_id,
      attributes: {
        verification_method: "SMS",
        phone_number: "+6427000000"
      }
    )
    expect(enroll_response).not_to be_nil

    # Get authenticators
    authenticators_response = described_class.get_authenticators(user_id: user_id)
    expect(authenticators_response[:data]).not_to be_empty
    expect(authenticators_response[:data].length).to be > 0

    authenticator = authenticators_response[:data].first

    expect(authenticator[:verificationMethod]).to eq("SMS")

    # Delete authenticator
    described_class.delete_authenticator(
      user_id: user_id,
      user_authenticator_id: authenticator[:userAuthenticatorId]
    )

    # Verify deletion
    empty_authenticators_response = described_class.get_authenticators(user_id: user_id)
    expect(empty_authenticators_response[:data]).to be_empty
  end

  it "action tests" do
    user_id = SecureRandom.uuid
    action = "Login"

    # Enroll user first
    enroll_response = described_class.enroll_verified_authenticator(
      user_id: user_id,
      attributes: {
        verification_method: "SMS",
        phone_number: "+6427000000"
      }
    )
    expect(enroll_response).not_to be_nil

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
      token: track_response[:token]
    )

    expect(validate_response).not_to be_nil
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
    expect(update_response).not_to be_nil

    # Get action
    action_response = described_class.get_action(
      user_id: user_id,
      action: action,
      idempotency_key: track_response[:idempotency_key]
    )
    expect(action_response).not_to be_nil
    expect(action_response[:state]).to eq("REVIEW_REQUIRED")
  end

  it "invalid secret error" do
    Authsignal.setup do |config|
      config.api_secret_key = "invalid_secret"
      config.api_url = api_url
    end

    begin
      described_class.get_user(user_id: SecureRandom.uuid)
    rescue Authsignal::Error => e
      expected_description = "The request is unauthorized. Check that your API key and region base URL are correctly configured."
      
      expect(e).to be_a(Authsignal::Error)
      expect(e.status_code).to eq(401)
      expect(e.error_code).to eq("unauthorized")
      expect(e.error_description).to eq(expected_description)
      expect(e.message).to eq("AuthsignalError: 401 - #{expected_description}")
    end
  end

  it "passkey authenticator" do
    user_id = "b60429a1-6288-43dc-80c0-6a3e73dd51b9"

    authenticators = described_class.get_authenticators(user_id: user_id)
    expect(authenticators[:data]).not_to be_empty
    expect(authenticators[:data].length).to be > 0

    authenticators[:data].each do |authenticator|
      next unless authenticator[:verificationMethod] == "PASSKEY"

      name = authenticator.dig(:webauthnCredential, :aaguidMapping, :name)
      expect(name).not_to be_nil
      expect(["Google Password Manager", "iCloud Keychain"]).to include(name)
      
      browser_name = authenticator.dig(:webauthnCredential, :parsedUserAgent, :browser, :name)
      expect(browser_name).to eq("Chrome")
    end
  end
end
