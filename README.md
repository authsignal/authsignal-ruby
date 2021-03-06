# Authsignal Server Ruby SDK

[Authsignal](https://www.authsignal.com/?utm_source=github&utm_medium=ruby_sdk) provides passwordless step up authentication (Multi-factor Authentication - MFA) that can be placed anywhere within your application. Authsignal also provides a no-code fraud risk rules engine to manage when step up challenges are triggered.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "authsignal-ruby"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install authsignal-ruby

## Configuration
Initialize the Authsignal Ruby SDK, ensuring you do not hard code the Authsignal Secret Key, always keep this safe.

In Ruby on Rails, you would typically place this code block in a file like `config/initializers/authsignal.rb`

```ruby
Authsignal.setup do |config|
    config.api_secret_key = ENV["AUTHSIGNAL_SECRET_KEY"]
end
```

## Usage

Authsignal's server side signal API has four main calls `track_action`, `get_action`, `get_user`, `identify`

These examples assume that the SDK is being called from a Ruby on Rails app, adapt depending on your server framework.

### Track Action
The track action call is the main api call to send actions to authsignal, the default decision is to `ALLOW` actions, this allows you to call track action as a means to keep an audit trail of your user activity.

Add to the rules in the admin portal or the change default decision to influence the flows for your end users. If a user is not enrolled with authenticators, the default decision is to `ALLOW`.

```ruby
# OPTIONAL: The Authsignal cookie available when using the authsignal browser Javascript SDK
# you could you use own device/session/fingerprinting identifiers.
authsignal_cookie = request.cookies["__as_aid"]

# OPTIONAL: The idempotencyKey is a unique identifier per track action
# this could be for a unique object associated to your application
# like a shopping cart check out id
# If ommitted, Authsignal will generate the idempotencyKey and return in the response
idempotency_key = SecureRandom.uuid

# OPTIONAL: If you're using a redirect flow, set the redirect URL, this is the url authsignal will redirect to after a Challenge is completed.
redirect_url = "https://www.yourapp.com/back_to_your_app"

response = Authsignal.track_action({
        action_code: "signIn",
        idempotency_key: idempotency_key,
        redirect_url: redirect_url,
        user_id: current_user.id,
        email: current_user.email,
        device_id: authsignal_cookie,
        user_agent: request.user_agent,
        ip_address: request.ip,
        custom: {
            it_could_be_a_bool: true,
            it_could_be_a_string: "test",
            it_could_be_a_number: 400.00
        }
    }
)
```
*Response*
```ruby
response = Authsignal.track_action({..})
case response[:state]
when "ALLOW"
    # Carry on with your operation/business logic
when "BLOCK"
    # Stop your operations
when "CHALLENGE_REQUIRED"
    # Step up authentication required, redirect or pass the challengeUrl to the front end
    response[:challenge_url]
end
```

### Get Action
Call get action after a challenge is completed by the user, after a redirect or a succesful browser challenge pop-up flow, and if the state of the action is `CHALLENGE_SUCCEEDED` you can proceed with completing the business logic.

```ruby
response = Authsignal.get_action(
    user_id: current_user.id,
    action_code: "testAction",
    idempotency_key: "15cac140-f639-48c5-92db-835ec8d3d144")

if(response[:state] === "CHALLENGE_SUCCEEDED")
    # The user has successfully completed the challenge, and you should proceed with
    # the business logic
end
```

### Get User
Get user retrieves the current enrolment state of the user, use this call to redirect users to the enrolment or management flows so that the user can do self service management of their authenticator factors. User the `url` in the response to either redirect or initiate the pop up client side flow.

```ruby
response = Authsignal.get_user(user_id: current_user.id, redirect_url: "http://www.yourapp.com/path-back")

is_enrolled = response[:is_enrolled]
url = response[:url]
```

### Identify
Get identify to link and update additional user indetifiers (like email) to the primary record.

```ruby
Authsignal.identify(user_id: current_user.id, user: { email: "newemail@email.com" })
```

### Enrol Authenticator
If your application already has a valid authenticator like a validated phone number for your customer, you can enrol the authenticator on behalf of the user using this function

```ruby
Authsignal.enrol_authenticator(user_id: current_user.id, authenticator:{ oob_channel: "SMS", phone_number: "+64270000000" })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
