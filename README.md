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

### Response & Error handling

The Authsignal SDK offers two response formats. By default, its methods return the payload in hash format.

Example:

```ruby
Authsignal.enroll_verified_authenticator(
  user_id: 'AS_001',
  attributes: {
    verification_method: 'INVALID',
    email: 'hamish@authsignal.com'
  }
)

# returns:
{
  "error": "invalid_request",
  "errorCode": "invalid_request",
  "errorDescription": "body.verificationMethod must be equal to one of the allowed values - allowedValues: AUTHENTICATOR_APP,EMAIL_MAGIC_LINK,EMAIL_OTP,SMS"
}
```

All methods have a bang (!) counterpart that raises an Authsignal::ApiError if the request fails.

Example:

```ruby
Authsignal.enroll_verified_authenticator!(
  user_id: 'AS_001',
  attributes: {
    verification_method: 'INVALID',
    email: 'hamish@authsignal.com'
  }
)

# raise:
<Authsignal::ApiError: AuthsignalError: 400 - body.verificationMethod must be equal to one of the allowed values - allowedValues: AUTHENTICATOR_APP,EMAIL_MAGIC_LINK,EMAIL_OTP,SMS.
```