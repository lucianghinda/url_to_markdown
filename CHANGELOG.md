# Changelog

## [0.2.0] - 2026-04-10

### Added

- `actions:` keyword argument on `UrlToMarkdown.new`, `.convert`, `Processor#convert`, `Cloudflare::Processor#convert`, and `Cloudflare::Client#markdown` — passes an actions array to Cloudflare's Browser Rendering `/markdown` endpoint for JS evaluation before extraction (e.g. removing nav/footer/sidebar elements before conversion)
- `Configuration#default_actions` — set a gem-wide default actions array via `UrlToMarkdown.configure { |c| c.default_actions = [...] }`; per-call `actions:` takes precedence

### Notes

- Fully backward compatible — omitting `actions:` produces the same request payload as 0.1.0

## [0.1.0] - 2025-01-01

- Initial release
