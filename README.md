<img width="1070" alt="Authsignal" src="https://raw.githubusercontent.com/authsignal/authsignal-node/main/.github/images/authsignal.png">

# Authsignal Ruby SDK

[![Gem Version](https://img.shields.io/gem/v/authsignal-ruby.svg)](https://rubygems.org/gems/authsignal-ruby)
[![License](https://img.shields.io/github/license/authsignal/authsignal-ruby.svg)](https://github.com/authsignal/authsignal-ruby/blob/main/LICENSE.txt)

The official Authsignal Ruby library for server-side applications. Use this SDK to easily integrate Authsignal's multi-factor authentication (MFA) and passwordless features into your Ruby backend.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "authsignal-ruby"
```

And then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install authsignal-ruby
```

## Getting started

Initialize the Authsignal client with your secret key from the [Authsignal Portal](https://portal.authsignal.com/) and the API URL for your region.

```ruby
require 'authsignal'

# Initialize the client
Authsignal.setup do |config|
  config.api_secret_key = ENV['AUTHSIGNAL_SECRET_KEY']
  config.api_url = ENV['AUTHSIGNAL_API_URL'] # Use region-specific URL
end
```

### API URLs by region

| Region      | API URL                          |
| ----------- | -------------------------------- |
| US (Oregon) | https://api.authsignal.com/v1    |
| AU (Sydney) | https://au.api.authsignal.com/v1 |
| EU (Dublin) | https://eu.api.authsignal.com/v1 |

## License

This SDK is licensed under the [MIT License](LICENSE.txt).

## Documentation

For more information and advanced usage examples, refer to the official [Authsignal server-Side SDK documentation](https://docs.authsignal.com/sdks/server/overview).
