# frozen_string_literal: true

RSpec.describe Authsignal::Client do
  let(:api_url) { 'https://api.test.authsignal.com/v1/' }

  before do
    WebMock.disable_net_connect!
    Authsignal.setup do |config|
      config.api_secret_key = 'secret'
      config.api_url = api_url
      config.retry = true
      config.retries = 2
      config.open_timeout = 3
      config.timeout = 10
    end
  end

  after do
    WebMock.allow_net_connect!
  end

  it 'uses consistent retry and timeout defaults' do
    client = described_class.new
    connection = client.instance_variable_get(:@client)

    expect(Authsignal.configuration.retry).to be true
    expect(Authsignal.configuration.retries).to eq(2)
    expect(connection.options.open_timeout).to eq(3)
    expect(connection.options.timeout).to eq(10)
  end

  it 'retries safe requests twice on 5xx' do
    request = stub_request(:get, "#{api_url}users/user")
              .to_return({ status: 503, body: '{}' }, { status: 503, body: '{}' }, { status: 200, body: '{}' })

    described_class.new.get_user(user_id: 'user')

    expect(request).to have_been_requested.times(3)
  end

  it 'retries 429 responses' do
    request = stub_request(:get, "#{api_url}users/user")
              .to_return({ status: 429, headers: { 'Retry-After' => '0' }, body: '{}' }, { status: 200, body: '{}' })

    described_class.new.get_user(user_id: 'user')

    expect(request).to have_been_requested.times(2)
  end

  it 'retries transient network failures' do
    request = stub_request(:get, "#{api_url}users/user")
              .to_raise(Faraday::ConnectionFailed.new('connection reset'))
              .then.to_return(status: 200, body: '{}')

    described_class.new.get_user(user_id: 'user')

    expect(request).to have_been_requested.times(2)
  end

  it 'retries writes carrying an idempotency key' do
    request = stub_request(:post, "#{api_url}users/user/actions/withdrawal")
              .to_return({ status: 503, body: '{}' }, { status: 200, body: '{}' })

    described_class.new.track(
      user_id: 'user',
      action: 'withdrawal',
      attributes: { idempotency_key: 'key' }
    )

    expect(request).to have_been_requested.times(2)
  end

  it 'does not retry non-idempotent writes or 499 responses' do
    post_request = stub_request(:post, "#{api_url}users/user/actions/withdrawal").to_return(status: 503, body: '{}')
    challenge_request = stub_request(:get, "#{api_url}users/user").to_return(status: 499, body: '{}')
    client = described_class.new

    client.track(user_id: 'user', action: 'withdrawal', attributes: {})
    client.get_user(user_id: 'user')

    expect(post_request).to have_been_requested.once
    expect(challenge_request).to have_been_requested.once
  end

  it 'allows retries to be disabled' do
    Authsignal.configuration.retry = false
    request = stub_request(:get, "#{api_url}users/user").to_return(status: 503, body: '{}')

    described_class.new.get_user(user_id: 'user')

    expect(request).to have_been_requested.once
  end
end
