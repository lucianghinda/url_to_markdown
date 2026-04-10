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

client = UrlToMarkdown::Cloudflare::Client.new(
  token: ENV.fetch("CLOUDFLARE_API_TOKEN"),
  account_id: ENV.fetch("CLOUDFLARE_ACCOUNT_ID")
)

extra_headers = {}
extra_headers["x-vercel-protection-bypass"] = ENV["VERCEL_BYPASS_SECRET"] if ENV["VERCEL_BYPASS_SECRET"]

def print_result(label, result)
  puts "\n#{'=' * 60}"
  puts "Attempt: #{label}"
  puts "=" * 60

  if result.success?
    puts "[SUCCESS]"
    puts result.payload.to_s[0, 500]
    puts "..." if result.payload.to_s.length > 500
  else
    error = result.error
    puts "[FAILURE]"
    if error.respond_to?(:status_code)
      warn "  Status: #{error.status_code}"
      warn "  Body: #{error.response_body}" unless error.response_body.to_s.empty?
    elsif error.respond_to?(:message)
      warn "  #{error.message}"
    else
      warn "  #{error}"
    end
  end
end

attempts = [
  {
    label: "1. Baseline (with optional Vercel bypass header)",
    opts: { set_extra_http_headers: extra_headers.any? ? extra_headers : nil }
  },
  {
    label: "2. wait_for_timeout: 5000ms",
    opts: { wait_for_timeout_in_milliseconds: 5000 }
  },
  {
    label: "3. wait_for_selector: 'main'",
    opts: { wait_for_selector: "main" }
  },
  {
    label: "4. Realistic User-Agent header",
    opts: {
      set_extra_http_headers: extra_headers.merge(
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      )
    }
  },
  {
    label: "5. wait_for_timeout: 5000ms + Realistic User-Agent",
    opts: {
      wait_for_timeout_in_milliseconds: 5000,
      set_extra_http_headers: extra_headers.merge(
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      )
    }
  }
]

attempts.each do |attempt|
  result = client.markdown(url: url, **attempt[:opts].compact)
  print_result(attempt[:label], result)
end
