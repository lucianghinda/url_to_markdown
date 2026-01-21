# UrlToMarkdown

Convert URLs to Markdown via Cloudflare Browser Rendering API.

## Setup

```bash
bundle install
```

## Usage

```ruby
require "url_to_markdown"

UrlToMarkdown.configure do |config|
  config.cloudflare_api_token = ENV.fetch("CLOUDFLARE_API_TOKEN")
  config.cloudflare_account_id = ENV.fetch("CLOUDFLARE_ACCOUNT_ID")
end

result = UrlToMarkdown.convert("https://example.com")

if result.success?
  puts result.payload
else
  warn result.error.message
end
```

## Tests

```bash
bundle exec rake
```
