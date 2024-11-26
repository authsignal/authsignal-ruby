# frozen_string_literal: true

RSpec.describe Authsignal do
  let(:api_url) { 'http://localhost:8080/v1' }

  it "has a version number" do
    expect(Authsignal::VERSION).not_to be nil
  end

  before do
    Authsignal.setup do |config|
      config.api_secret_key = 'secret'
      config.api_url = api_url
    end
  end

  ##
  # NOTE: Response header has "content-type: text/plain" atm
  describe "with plain text response" do
    let(:idempotency_key) { "f7f6ff4c-600f-4d61-99a2-b1157fe43777" }
    let(:user_id) { 123 }
    let(:action) { 'signIn' }
    let(:url) { "#{api_url}/users/#{user_id}/actions/#{action}" }

    it 'handles plain text' do
      stub_request(:post, url)
        .with(basic_auth: ['secret', ''])
        .to_return(status: 401,
                   headers: { 'Content-Type' => 'text/plain' },
                   body: { error: "unauthorized", errorDescription: "Session expired" }.to_json )

      response = described_class.track(user_id: "123", action: "signIn", attributes: { idempotency_key: idempotency_key })
      expect(response).to eq status_code: 401, error_code: "unauthorized", error_description: "Session expired", success?: false
    end
  end

  describe ".get_user" do
    it 'succeeds' do
      stub_request(:get, "#{api_url}/users/1")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {isEnrolled: false, url: "https://www.example.com", accessToken: "xxx"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = described_class.get_user(user_id: 1)

      expect(response[:is_enrolled]).to eq(false)
      expect(response[:url]).to eq("https://www.example.com")
    end
  end

  describe ".update_user" do
    it 'succeeds' do
      stub_request(:post, "#{api_url}/users/1")
          .with(basic_auth: ['secret', ''], body: { email: "test@test.com" })
          .to_return(body: {userId: "1", email: "test@test.com"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})

      response = described_class.update_user(user_id: 1, attributes: { email: "test@test.com" })

      expect(response[:email]).to eq("test@test.com")
      expect(response[:success?]).to be true
    end
  end

  describe ".delete_user" do
    it 'succeeds' do
      stub_request(:delete, "#{api_url}/users/1")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {success: true}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})

      response = described_class.delete_user(user_id: 1)

      expect(response[:success]).to eq(true)
      expect(response[:success?]).to be true
    end
  end

  describe ".get_authenticators" do
    let(:user_id) { "100" }
    
    let(:authenticator) {{
        userAuthenticatorId: "18fbbe25-f84d-49ab-ab71-577adaefee25",
        verificationMethod: "EMAIL_MAGIC_LINK",
        createdAt: "2024-10-09T02:58:33.911Z",
        email: "email@authsignal.com",
        verifiedAt: "2024-10-09T02:59:19.995Z",
        lastVerifiedAt: "2024-10-09T02:59:19.995Z"     
    }}


    it "succeeds" do
      stub_request(:get, "#{api_url}/users/#{user_id}/authenticators")
          .with(
            basic_auth: ['secret', ''],
            headers: { 'Content-Type'=>'application/json' })
          .to_return(body: [authenticator].to_json,
            status: 200,
            headers: {'Content-Type' => 'application/json'})

      response = described_class.get_authenticators(
        user_id: user_id,
      ) 

      expect(response[:data]).to eq([authenticator])
      expect(response[:success?]).to be true      
    end
  end

  describe ".enroll_verified_authenticator" do
    it 'succeeds' do
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

      stub_request(:post, "#{api_url}/users/1/authenticators")
          .with(basic_auth: ['secret', ''])
          .with(body: { oobChannel:"SMS",phoneNumber:"+64270000000" })
          .to_return(body: payload.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = described_class.enroll_verified_authenticator(user_id: 1,
                    attributes:{ oob_channel: "SMS",
                      phone_number: "+64270000000" })

      expect(response).to eq({
                               success?: true,
                               authenticator:  {
                                 user_authenticator_id: "9b2cfd40-7df2-4658-852d-a0c3456e5a2e",
                                 authenticator_type:    "OOB",
                                 is_default:            true,
                                 phone_number:          "+64270000000",
                                 created_at:            "2022-07-25T03:31:36.219Z",
                                 oob_channel:           "SMS"
                               },
                               recovery_codes: ["xxxx"]
                             })
    end
  end

  describe ".delete_authenticator" do
    it 'succeeds' do
      stub_request(:delete, "#{api_url}/users/1/authenticators/9b2cfd40-7df2-4658-852d-a0c3456e5a2e")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {success: true}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})

      response = described_class.delete_authenticator(user_id: 1, user_authenticator_id: '9b2cfd40-7df2-4658-852d-a0c3456e5a2e')

      expect(response[:success]).to eq(true)
      expect(response[:success?]).to be true
    end
  end

  describe ".track" do
    let(:idempotency_key) { "f7f6ff4c-600f-4d61-99a2-b1157fe43777" }
    let(:user_id) { 123 }
    let(:action) { 'signIn' }
    let(:url) { "#{api_url}/users/#{user_id}/actions/#{action}" }

    it 'succeeds' do
      stub_request(:post, url)
        .with(basic_auth: ['secret', ''],
              body: {
                idempotencyKey: idempotency_key,
                redirectUrl: "https://wwww.example.com",
                email: "test@example.com",
                deviceId: "xxx",
                userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0",
                ipAddress: "1.1.1.1",
                custom: {
                  ###########################################################
                  # NOTE: user defined attributes should not be transformed #
                  ###########################################################
                  it_could_be_a_bool: true,
                  it_could_be_a_string: "test",
                  it_could_be_a_number: 400.00
                }
              })
        .to_return_json(body: { state: "ALLOW", idempotencyKey: idempotency_key, ruleIds: [] })

      response = described_class.track(user_id: user_id, action: action, attributes: {
                                    idempotency_key: idempotency_key,
                                    redirect_url: "https://wwww.example.com",
                                    email: "test@example.com",
                                    device_id: "xxx",
                                    user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0",
                                    ip_address: "1.1.1.1",
                                    custom: {
                                      it_could_be_a_bool: true,
                                      it_could_be_a_string: "test",
                                      it_could_be_a_number: 400.00
                                    }
                                  })

      expect(response).to include  state: "ALLOW", idempotency_key: idempotency_key, rule_ids: [], success?: true
    end

    it 'handles blank response' do
      stub_request(:post, url)
        .with(basic_auth: ['secret', ''])
        .to_return(status: 400)

      response = described_class.track(action: "signIn", user_id: "123", attributes: { idempotency_key: idempotency_key })
      expect(response).to eq status_code: 400, success?: false
    end

    it 'handles errors' do
      stub_request(:post, url)
        .with(basic_auth: ['secret', ''])
        .to_return_json(status: 401, body: { error: "unauthorized", errorDescription: "Session expired" } )

      response = described_class.track(action: "signIn", user_id: "123", attributes: { idempotency_key: idempotency_key })
      expect(response).to eq status_code: 401, error_code: "unauthorized", error_description: "Session expired", success?: false
    end

  end

  describe ".validate_challenge" do
    it "Checks that the isValid is true when userId correct" do
      stub_request(:post, "#{api_url}/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        },
        body: { userId: "legitimate_user_id", token: "token" })
      .to_return(
        status: 200, 
        body: {
          "isValid":true,
          "state":"CHALLENGE_SUCCEEDED",
          "stateUpdatedAt":"2024-04-11T22:30:52.317Z",
          "userId":"legitimate_user_id",
          "action":"alwaysChallenge",
          "idempotencyKey":"aaafac77-42c9-486f-9a6e-086b63f32a5c",
          "verificationMethod":"AUTHENTICATOR_APP"
        }.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = described_class.validate_challenge(
        user_id: "legitimate_user_id",
        token: "token",
      )

      expect(response[:user_id]).to eq("legitimate_user_id")
      expect(response[:state]).to eq("CHALLENGE_SUCCEEDED")
      expect(response[:is_valid]).to eq(true)
      expect(response[:success?]).to be true
    end

    it "Checks that isValid is false when userId is incorrect" do
      stub_request(:post, "#{api_url}/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        },
        body: { userId: "spoofed_user_id", token: "token" })
      .to_return(
        status: 200, 
        body: {
          "isValid":false,
          "error": "User is invalid."
        }.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = described_class.validate_challenge(
        user_id: "spoofed_user_id",
        token: "token",
      )

      expect(response[:user_id]).to eq(nil)
      expect(response[:state]).to eq(nil)
      expect(response[:is_valid]).to eq(false)
      expect(response[:success?]).to be true
    end

    it "Checks that isValid is false when action is invalid" do
      stub_request(:post, "#{api_url}/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        },
        body: { userId: "legitimate_user_id", token: "token", action: "invalid_action" })
      .to_return(
        status: 200, 
        body: {
          "isValid":false,
          "error":"Action is invalid."
        }.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = described_class.validate_challenge(
        user_id: "legitimate_user_id",
        action: "invalid_action",
        token: "token",
      )

      expect(response[:is_valid]).to eq(false)
      expect(response[:success?]).to be true
    end

    it "Checks that an error is thrown when an unknown error is returned from Authsignal" do
      stub_request(:post, "#{api_url}/validate")
      .with(
        headers: {
          'Content-Type'=>'application/json',
        })
      .to_return(
        status: 404, 
        body: {"error":"unauthorized", "errorDescription":"The request is unauthorized. Check that your API key and region api URL are correctly configured."}.to_json, 
        headers: {'Content-Type' => 'application/json'}
      )

      response = described_class.validate_challenge(
        user_id: "legitimate_user_id",
        token:   "token",
      )

      expect(response).to eq error_code: "unauthorized", status_code: 404, error_description: "The request is unauthorized. Check that your API key and region api URL are correctly configured.", success?: false
    end
  end

  describe ".get_action" do
    it 'succeeds' do
      stub_request(:get, "#{api_url}/users/1/actions/testAction/15cac140-f639-48c5-92db-835ec8d3d144")
          .with(basic_auth: ['secret', ''])
          .to_return(body: {state: "ALLOW", ruleIds: [], stateUpdatedAt: "2022-07-25T03:19:00.316Z", createdAt: "2022-07-25T03:19:00.316Z"}.to_json,
                    status: 200,
                    headers: {'Content-Type' => 'application/json'})
        
      response = described_class.get_action(
        user_id: 1,
        action: "testAction",
        idempotency_key: "15cac140-f639-48c5-92db-835ec8d3d144")
    

      expect(response[:state]).to eq("ALLOW")
      expect(response[:state_updated_at]).to eq("2022-07-25T03:19:00.316Z")
      expect(response[:success?]).to be true
    end
  end

  describe ".update_action" do
    let(:user_id) { "100" }
    let(:action) { "testAction" }
    let(:idempotency_key) { "15cac140-f639-48c5-92db-835ec8d3d144" }
    let(:state) { "ALLOW" }

    it "succeeds" do
      stub_request(:patch, "#{api_url}/users/#{user_id}/actions/#{action}/#{idempotency_key}")
          .with(
            basic_auth: ['secret', ''],
            headers: { 'Content-Type'=>'application/json' })
          .to_return(body: {state: state, ruleIds: [], stateUpdatedAt: "2024-11-01T03:19:00.316Z", createdAt: "2024-11-01T03:19:00.316Z"}.to_json,
            status: 200,
            headers: {'Content-Type' => 'application/json'})

      response = described_class.update_action(
        user_id: user_id,
        action: action, 
        idempotency_key: idempotency_key,
        attributes: { state: state }
      ) 

      expect(response[:state]).to eq(state)
      expect(response[:state_updated_at]).to eq("2024-11-01T03:19:00.316Z")
      expect(response[:success?]).to be true      
    end
  end
end
