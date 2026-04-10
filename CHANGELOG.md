# Changelog

## [0.2.2] - 2026-04-10

### Fixed

- `Cloudflare::Client` now returns `Result.failure` with `SecurityCheckpointError` when the rendered content is a security checkpoint page (Vercel Firewall, Cloudflare challenge, etc.) instead of falsely returning `Result.success` with the checkpoint HTML as content

### Added

- `UrlToMarkdown::SecurityCheckpointError` — new error class (subclass of `Error`) raised when a security checkpoint is detected in the rendered output

## [0.2.0] - 2026-04-10

### Added

- `actions:` keyword argument on `UrlToMarkdown.new`, `.convert`, `Processor#convert`, `Cloudflare::Processor#convert`, and `Cloudflare::Client#markdown` — passes an actions array to Cloudflare's Browser Rendering `/markdown` endpoint for JS evaluation before extraction (e.g. removing nav/footer/sidebar elements before conversion)
- `Configuration#default_actions` — set a gem-wide default actions array via `UrlToMarkdown.configure { |c| c.default_actions = [...] }`; per-call `actions:` takes precedence

### Notes

- Fully backward compatible — omitting `actions:` produces the same request payload as 0.1.0

## [0.1.0] - 2025-01-01

- Initial release
