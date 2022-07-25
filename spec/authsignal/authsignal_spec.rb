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

  describe "track_action" do
    it do 
      stub_request(:post, "http://localhost:8080/users/123/actions/signIn")
        .with(basic_auth: ['secret', ''])
        .to_return(body: "{\"state\":\"ALLOW\",\"idempotencyKey\":\"f7f6ff4c-600f-4d61-99a2-b1157fe43777\",\"ruleIds\":[]}", 
        headers: {'Content-Type' => 'application/json'},
        status: 200)

      response = Authsignal.track_action({
                      action_code: "signIn",
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
end
