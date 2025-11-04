#!/usr/bin/env ruby

# Example: Webhook Verification
# 
# This example demonstrates how to verify webhook signatures from Authsignal
# in a Ruby application.

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'authsignal'

Authsignal.setup do |config|
  config.api_secret_key = ENV['AUTHSIGNAL_API_SECRET_KEY'] || 'your_api_secret_key'
  config.api_url = ENV['AUTHSIGNAL_API_URL'] || 'https://api.authsignal.com/v1'
end

def handle_webhook(payload, signature)
  begin
    event = Authsignal.webhook.construct_event(payload, signature)
    
    puts "✅ Webhook verified successfully!"
    puts "\nEvent Details:"
    puts "  Type: #{event[:type]}"
    puts "  ID: #{event[:id]}"
    puts "  Tenant ID: #{event[:tenantId]}"
    puts "  Time: #{event[:time]}"
    
    case event[:type]
    when 'email.created'
      puts "\nEmail Event:"
      puts "  Recipient: #{event[:data][:to]}"
      puts "  User ID: #{event[:data][:userId]}"
      puts "  Action: #{event[:data][:actionCode]}"
      
    when 'sms.created'
      puts "\nSMS Event:"
      puts "  Recipient: #{event[:data][:to]}"
      puts "  User ID: #{event[:data][:userId]}"
      puts "  Action: #{event[:data][:actionCode]}"
      
    when 'action.created'
      puts "\nAction Event:"
      puts "  User ID: #{event[:data][:userId]}"
      puts "  Action: #{event[:data][:actionCode]}"
      puts "  State: #{event[:data][:state]}"
      
    else
      puts "\nUnknown event type: #{event[:type]}"
    end
    
    return { status: :ok }
  rescue Authsignal::InvalidSignatureError => e
    puts "❌ Webhook verification failed: #{e.message}"
    return { status: :bad_request, error: e.message }
  end
end

if __FILE__ == $0
  puts "Authsignal Webhook Verification Example"
  puts "=" * 50
  
  sample_payload = '{
    "version": 1,
    "type": "email.created",
    "id": "evt_123456",
    "source": "https://authsignal.com",
    "time": "2025-02-20T01:51:56.070Z",
    "tenantId": "tenant_123",
    "data": {
      "to": "user@example.com",
      "code": "123456",
      "userId": "user_123",
      "actionCode": "signIn",
      "idempotencyKey": "key_123",
      "verificationMethod": "EMAIL_OTP"
    }
  }'
  
  sample_signature = "t=1740016316,v2=fake_signature_for_demo"
  
  puts "\nNote: This example will fail verification because we're using"
  puts "      a fake signature. In production, Authsignal will send real"
  puts "      signatures that can be verified with your API secret key."
  puts ""
  
  result = handle_webhook(sample_payload, sample_signature)
  puts "\nResult: #{result[:status]}"
end

# Example Rails controller integration
#
# class WebhooksController < ApplicationController
#   skip_before_action :verify_authenticity_token
#
#   def authsignal
#     payload = request.body.read
#     signature = request.headers['Authsignal-Signature']
#
#     begin
#       event = Authsignal.webhook.construct_event(payload, signature)
#
#       process_event(event)
#
#       head :ok
#     rescue Authsignal::InvalidSignatureError => e
#       Rails.logger.error("Webhook verification failed: #{e.message}")
#       head :bad_request
#     end
#   end
#
#   private
#
#   def process_event(event)
#     case event[:type]
#     when 'email.created'
#       # Handle email created
#     when 'action.created'
#       # Handle action created
#     end
#   end
# end
