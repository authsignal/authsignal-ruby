<img width="1070" alt="Authsignal" src="https://raw.githubusercontent.com/authsignal/authsignal-node/main/.github/images/authsignal.png">

# Authsignal Ruby SDK

The Authsignal Ruby library for server-side applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "authsignal-ruby"
```

## Documentation

Refer to our [SDK documentation](https://docs.authsignal.com/sdks/server/overview) for information on how to use this SDK.

Or check out our [Ruby on Rails Quickstart Guide](https://docs.authsignal.com/quickstarts/ruby-on-rails).

## Usage

Example:

```ruby
Authsignal.track(
  user_id: 'AS_001',
  action: 'withdraw',
  attributes: {
    idempotency_key: 'a_random_hash'
  },
)

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
Authsignal.enroll_verified_authenticator(
  user_id: 'AS_001',
  attributes: {
    oob_channel: 'INVALID',
    email: 'joebloke@authsignal.com'
  }
)

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
Authsignal.enroll_verified_authenticator!(
  user_id: 'AS_001',
  attributes: {
    oob_channel: 'INVALID',
    email: 'joebloke@authsignal.com'
  }
)

# raise:
# <Authsignal::ApiError: AuthsignalError: 400 - /body/oobChannel must be equal to one of the allowed values. status_code: 401, error_code: invalid_request, error_description: /body/oobChannel must be equal to one of the allowed values.
```