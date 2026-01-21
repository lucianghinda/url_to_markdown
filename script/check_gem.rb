#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

lib_path = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
require "url_to_markdown"

url = ARGV[0]

if url.nil?
  warn "URL missing. Execute ./script/check_gem.rb <URL>"
  exit 2
end

missing = %w[CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID].reject { |key| ENV.key?(key) }
if missing.any?
  warn "Missing env vars: #{missing.join(', ')}"
  warn "Usage: CLOUDFLARE_API_TOKEN=... CLOUDFLARE_ACCOUNT_ID=... #{File.basename($PROGRAM_NAME)} [url]"
  exit 2
end

UrlToMarkdown.configure do |config|
  config.cloudflare_api_token = ENV.fetch("CLOUDFLARE_API_TOKEN")
  config.cloudflare_account_id = ENV.fetch("CLOUDFLARE_ACCOUNT_ID")
end

result = UrlToMarkdown.convert(url)

if result.success?
  puts result.payload
else
  error = result.error
  if error.respond_to?(:status_code)
    warn "Request failed (status #{error.status_code})."
    warn error.response_body unless error.response_body.to_s.empty?
  elsif error.respond_to?(:message)
    warn error.message
  else
    warn error
  end
  exit 1
end
