# UrlToMarkdown

Convert URLs (or raw HTML) into Markdown using a configurable processor.
Cloudflare Browser Rendering is the default processor, but you can plug in your own.

- Uses Cloudflare's rendering service for JavaScript-heavy pages by default.
- Returns results as `SimpleResult::Success` / `SimpleResult::Failure`.
- Supports optional caching via `UrlToMarkdown::CacheStore::PStore`.

> Cloudflare Browser Rendering docs: https://workers.cloudflare.com/product/browser-rendering/

## Requirements

- Ruby 4.0.1
- Cloudflare API token and account ID

## Installation

```bash
bundle install
```

## Configuration

```ruby
require 'url_to_markdown'

UrlToMarkdown.configure do |config|
  config.cloudflare_api_token = ENV.fetch('CLOUDFLARE_API_TOKEN')
  config.cloudflare_account_id = ENV.fetch('CLOUDFLARE_ACCOUNT_ID')
  config.cloudflare_timeout_ms = 30_000
  config.cloudflare_cache_ttl = 5
  config.logger = Logger.new($stdout)
end
```

## Basic Usage

```ruby
result = UrlToMarkdown.convert('https://example.com')

if result.success?
  puts result.payload
else
  warn result.error.message
end
```

## Using a Cache Store

`UrlToMarkdown` checks the cache before calling the processor. If `cache_store.exists?(url)` returns
true, it returns the cached content from `cache_store.find_by(url)`. When the processor succeeds,
it writes the markdown with `cache_store.store!(url, result.payload)`.

```ruby
cache = UrlToMarkdown::CacheStore::PStore.new(path: '/tmp/url_to_markdown.pstore')
converter = UrlToMarkdown.new(url: 'https://example.com', cache_store: cache)

result = converter.convert
puts result.payload if result.success?
```

### Implementing Your Own Cache Store

Implement the `UrlToMarkdown::CacheStore` interface with these methods:

- `exists?(key)` → boolean
- `find_by(key)` → cached value (raise `CacheReadError` if missing)
- `store!(key, value)`
- `invalidate!(key)`
- `clear!`

Example in-memory cache:

```ruby
class MemoryCache < UrlToMarkdown::CacheStore
  def initialize
    @store = {}
  end

  def exists?(key)
    @store.key?(key)
  end

  def find_by(key)
    @store.fetch(key) do
      raise UrlToMarkdown::CacheReadError.new(nil, 'Cache miss')
    end
  end

  def store!(key, value)
    @store[key] = value
  end

  def invalidate!(key)
    @store.delete(key)
  end

  def clear!
    @store.clear
  end
end
```

## Custom Processor Options

Use the Cloudflare processor directly for advanced options such as HTML input or dynamic rendering.

```ruby
processor = UrlToMarkdown::Cloudflare::Processor.new(
  config: UrlToMarkdown.configuration,
  logger: Logger.new($stdout)
)

result = processor.convert('https://example.com')
```

### Implementing Your Own Processor

Custom processors must implement `convert(url)` and return a `SimpleResult::Success` or
`SimpleResult::Failure`. You can also accept a `logger:` and `cache_store:` in `initialize` to match
the base processor signature.

```ruby
class StaticProcessor < UrlToMarkdown::Processor
  def initialize(logger: nil, cache_store: nil)
    super
  end

  def convert(url)
    markdown = "# Offline content for #{url}"
    UrlToMarkdown::Result.success(markdown)
  rescue StandardError => e
    UrlToMarkdown::Result.failure(UrlToMarkdown::Error.new(e))
  end
end

UrlToMarkdown.configure do |config|
  config.default_processor = StaticProcessor
end
```

### Rendering HTML Instead of a URL

```ruby
client = UrlToMarkdown::Cloudflare::Client.new(
  token: ENV.fetch('CLOUDFLARE_API_TOKEN'),
  account_id: ENV.fetch('CLOUDFLARE_ACCOUNT_ID')
)

result = client.markdown(html: '<h1>Hello</h1>')
puts result.payload if result.success?
```

### Waiting for Dynamic Content

```ruby
client = UrlToMarkdown::Cloudflare::Client.new(
  token: ENV.fetch('CLOUDFLARE_API_TOKEN'),
  account_id: ENV.fetch('CLOUDFLARE_ACCOUNT_ID')
)

result = client.markdown(
  url: 'https://spa-example.com',
  wait_for_selector: '#main-content',
  wait_for_timeout_in_milliseconds: 10_000
)
```

## Error Handling

Failures return a `SimpleResult::Failure` with a rich error type. Common errors include:

- `UrlToMarkdown::MissingCredentialsError`
- `UrlToMarkdown::AuthenticationError`
- `UrlToMarkdown::RateLimitError`
- `UrlToMarkdown::ServerError`
- `UrlToMarkdown::InvalidUrlError`

```ruby
result = UrlToMarkdown.convert('https://example.com')

result.on_error do |error|
  warn "Conversion failed: #{error.class} - #{error.message}"
end
```

## Contributing

### Environment Variables

Set the Cloudflare credentials before running integration or manual checks:

```bash
export CLOUDFLARE_API_TOKEN="your-token"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
```

### Tests

```bash
bundle exec rake test
```

### Sorbet

```bash
bundle exec srb tc
```

### RuboCop

```bash
bundle exec rubocop
```
