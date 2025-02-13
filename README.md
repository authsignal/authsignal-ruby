# Authsignal Server Ruby SDK

Check out our [official Ruby SDK documentation](https://docs.authsignal.com/sdks/server/ruby), and [Ruby on Rails Quickstart Guide](https://docs.authsignal.com/quickstarts/ruby-on-rails).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "authsignal-ruby"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install authsignal-ruby

## Initialization

Initialize the Authsignal Ruby SDK, ensuring you do not hard code the Authsignal Secret Key, always keep this safe.

In Ruby on Rails, you would typically place this code block in a file like `config/initializers/authsignal.rb`

```ruby
Authsignal.setup do |config|
    config.api_secret_key = ENV["AUTHSIGNAL_SECRET_KEY"]
end
```

You can find your `api_secret_key` in the [Authsignal Portal](https://portal.authsignal.com/organisations/tenants/api).

You must specify the correct `api_url` for your tenant's region.

| Region      | API URL                             |
| ----------- | ----------------------------------- |
| US (Oregon) | https://signal.authsignal.com/v1    |
| AU (Sydney) | https://au.signal.authsignal.com/v1 |
| EU (Dublin) | https://eu.signal.authsignal.com/v1 |

For example, to set the API URL to use our AU region:

```
require 'authsignal'

Authsignal.setup do |config|
    config.api_secret_key = ENV["AUTHSIGNAL_SECRET_KEY"]
    config.api_url = "https://au.signal.authsignal.com/v1"

    # If you would like the Authsignal client to retry requests due to network issues
    config.retry = true # default value: false

    # If you would like to inspect raw request/response in development
    config.debug = true # default value: false
end
```

## Usage

Authsignal's server side signal API has four main api calls `track`, `get_action`, `get_user`, `enroll_verified_authenticator`.

For more details on these api calls, refer to our [official Ruby SDK docs](https://docs.authsignal.com/sdks/server/ruby#track).

Example:

```ruby
Authsignal.track user_id: 'AS_001', action: 'withdraw', idempotency_key: 'a_random_hash'

# returns:
# {
#    success?: true,
#    state: 'ALLOW',
#    idempotency_key: 'a_random_hash',
#    ... rest of payload ...
# }
```

### Response & Error handling

The Authsignal SDK offers two response formats. By default, its methods return the payload in hash format.

Example:

```ruby
Authsignal.enroll_verified_authenticator user_id: 'AS_001',
                                         authenticator: {
                                           oob_channel: 'INVALID', email: 'joebloke@authsignal.com'
                                         }

# returns:
# {
#    success?: false,
#    status_code: 400,
#    error_code: 'invalid_request',
#    error_description: '/body/oobChannel must be equal to one of the allowed values'
# }
```

All methods have a bang (!) counterpart that raises an Authsignal::ApiError if the request fails.

Example:

```ruby
Authsignal.enroll_verified_authenticator! user_id: 'AS_001',
                                         authenticator: {
                                           oob_channel: 'INVALID', email: 'joebloke@authsignal.com'
                                         }

# raise:
# <Authsignal::ApiError: AuthsignalError: 400 - /body/oobChannel must be equal to one of the allowed values. status_code: 401, error_code: invalid_request, error_description: /body/oobChannel must be equal to one of the allowed values.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` or `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Log request/response against test server: `Authsignal.configuration.debug = true`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
