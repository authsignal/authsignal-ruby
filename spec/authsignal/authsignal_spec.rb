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

  describe "update_user" do
    it do
      stub_request(:post, "http://localhost:8080/users/1")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {userId: "1", email: "test@test.com"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})

      response = Authsignal.update_user(user_id: 1, user: {email: "test@test.com"})

      expect(response[:email]).to eq("test@test.com")
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
        action: "testAction",
        idempotency_key: "15cac140-f639-48c5-92db-835ec8d3d144")
    

      expect(response[:state]).to eq("ALLOW")
      expect(response[:state_updated_at]).to eq("2022-07-25T03:19:00.316Z")
    end
  end

  describe "validate_challenge" do
    it "Checks that the isValid is true when userId correct" do
      stub_request(:post, "http://localhost:8080/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        })
      .to_return(
        status: 200, 
        body: {
          "isValid":true,
          "state":"CHALLENGE_SUCCEEDED",
          "stateUpdatedAt":"2024-04-11T22:30:52.317Z",
          "userId":"legitimate_user_id",
          "actionCode":"alwaysChallenge",
          "idempotencyKey":"aaafac77-42c9-486f-9a6e-086b63f32a5c",
          "verificationMethod":"AUTHENTICATOR_APP"
        }.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = Authsignal.validate_challenge(
        user_id: "legitimate_user_id",
        token: "token",
      )

      expect(response[:user_id]).to eq("legitimate_user_id")
      expect(response[:state]).to eq("CHALLENGE_SUCCEEDED")
      expect(response[:is_valid]).to eq(true)
    end

    it "Checks that isValid is false when userId is incorrect" do
      stub_request(:post, "http://localhost:8080/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        })
      .to_return(
        status: 200, 
        body: {
          "isValid":false,
        }.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = Authsignal.validate_challenge(
        user_id: "spoofed_user_id",
        token: "token",
      )

      expect(response[:user_id]).to eq(nil)
      expect(response[:state]).to eq(nil)
      expect(response[:is_valid]).to eq(false)
    end

    it "Checks that an error is thrown when an unknown error is returned from Authsignal" do
      stub_request(:post, "http://localhost:8080/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        })
      .to_return(
        status: 404, 
        body: {"message":"Not Found"}.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      expect {
        Authsignal.validate_challenge(
        user_id: "legitimate_user_id",
        token: "token",
      )
      }.to raise_error(HTTParty::ResponseError)
      
    end
  end
end
