# frozen_string_literal: true

RSpec.describe Authsignal do
  it "has a version number" do
    expect(Authsignal::VERSION).not_to be nil
  end

  before do
    Authsignal.setup do |config|
      config.api_secret_key = 'secret'
      config.base_uri = "http://localhost:8080"
    end
  end

  describe "get_user" do
    it do
      stub_request(:get, "http://localhost:8080/users/1")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {isEnrolled: false, url: "https://www.example.com", accessToken: "xxx"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = Authsignal.get_user(user_id: 1)

      expect(response[:is_enrolled]).to eq(false)
      expect(response[:url]).to eq("https://www.example.com")
    end
  end

  describe "enroll_verified_authenticator" do
    it do
      payload = {
        authenticator: {
          userAuthenticatorId: "9b2cfd40-7df2-4658-852d-a0c3456e5a2e",
          authenticatorType: "OOB",
          isDefault: true,
          phoneNumber: "+64270000000",
          createdAt: "2022-07-25T03:31:36.219Z",
          oobChannel: "SMS"
        },
        recoveryCodes: ["xxxx"]
      }

      stub_request(:post, "http://localhost:8080/users/1/authenticators")
          .with(basic_auth: ['secret', ''])
          .with(body: "{\"oobChannel\":\"SMS\",\"phoneNumber\":\"+64270000000\"}")
          .to_return(body: payload.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = Authsignal.enroll_verified_authenticator(user_id: 1,
                    authenticator:{ oob_channel: "SMS",
                      phone_number: "+64270000000" })

      expect(response[:authenticator][:user_authenticator_id]).to eq("9b2cfd40-7df2-4658-852d-a0c3456e5a2e")
    end
  end

  describe "track" do
    it do 
      stub_request(:post, "http://localhost:8080/users/123/actions/signIn")
        .with(basic_auth: ['secret', ''])
        .to_return(body: "{\"state\":\"ALLOW\",\"idempotencyKey\":\"f7f6ff4c-600f-4d61-99a2-b1157fe43777\",\"ruleIds\":[]}", 
        headers: {'Content-Type' => 'application/json'},
        status: 200)

      response = Authsignal.track({
                      action: "signIn",
                      idempotency_key: "xxxx-xxxx",
                      redirect_url: "https://wwww.example.com",
                      user_id: "123",
                      email: "test@example.com",
                      device_id: "xxx",
                      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0",
                      ip_address: "1.1.1.1",
                      custom: {
                          it_could_be_a_bool: true,
                          it_could_be_a_string: "test",
                          it_could_be_a_number: 400.00
                      }
                  }
              )
      
      expect(response[:state]).to eq("ALLOW")
      expect(response[:idempotency_key]).to eq("f7f6ff4c-600f-4d61-99a2-b1157fe43777")
    end
  end

  describe "get_action" do
    it do
      stub_request(:get, "http://localhost:8080/users/1/actions/testAction/15cac140-f639-48c5-92db-835ec8d3d144")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {state: "ALLOW", ruleIds: [], stateUpdatedAt: "2022-07-25T03:19:00.316Z", createdAt: "2022-07-25T03:19:00.316Z"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = Authsignal.get_action(
        user_id: 1,
        action_code: "testAction",
        idempotency_key: "15cac140-f639-48c5-92db-835ec8d3d144")
    

      expect(response[:state]).to eq("ALLOW")
      expect(response[:state_updated_at]).to eq("2022-07-25T03:19:00.316Z")
    end
  end

  describe "validate_challenge" do
    before do
      stub_request(:get, "http://localhost:8080/users/legitimate_user_id/actions/alwaysChallenge/a682af7d-c929-4c29-9c2a-71e69ab5c603")
      .with(basic_auth: ['secret', ''])
      .to_return(body: {success: true, state: "CHALLENGE_SUCCEEDED", user_id: "legitimate_user_id", stateUpdatedAt: "2022-07-25T03:19:00.316Z", createdAt: "2022-07-25T03:19:00.316Z"}.to_json,
                status: 200,
                headers: {'Content-Type' => 'application/json'})
    end

    payload = { 
      "iat": Time.now.to_i, 
      "sub": "legitimate_user_id", 
      "exp": Time.now.to_i + 10 * 60, 
      "iss": "https://challenge.authsignal.com/555159e4-adc3-454b-82b1-b55a2783f712", 
      "aud": "https://challenge.authsignal.com/555159e4-adc3-454b-82b1-b55a2783f712", 
      "scope": "read:authenticators add:authenticators update:authenticators remove:authenticators", 
      "other": { 
        "tenantId": "555159e4-adc3-454b-82b1-b55a2783f712", 
        "publishableKey": "2fff14a6600b7a58170793109c78b876", 
        "userId": "legitimate_user_id", 
        "actionCode": "alwaysChallenge", 
        "idempotencyKey": "a682af7d-c929-4c29-9c2a-71e69ab5c603" 
      } 
    }

    hmac_secret = 'secret'

    token = JWT.encode payload, hmac_secret, 'HS256'

    it "Checks that the challenge was successful when userId correct" do
      response = Authsignal.validate_challenge(
        user_id: "legitimate_user_id",
        token: token,
      )

      expect(response[:user_id]).to eq("legitimate_user_id")
      expect(response[:state]).to eq("CHALLENGE_SUCCEEDED")
      expect(response[:success]).to eq(true)
    end

    it "Checks that success is false when userId is incorrect" do
      response = Authsignal.validate_challenge(
        user_id: "spoofed_user_id",
        token: token,
      )

      expect(response[:state]).to eq(nil)
      expect(response[:success]).to eq(false)
    end
  end
end
