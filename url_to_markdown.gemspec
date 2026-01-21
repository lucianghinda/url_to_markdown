# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "url_to_markdown"
  spec.version = "0.1.0"
  spec.authors = ["Lucian Ghinda"]
  spec.email = ["lucian@example.com"]

  spec.summary = "Convert URLs to Markdown via Cloudflare Browser Rendering"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 4.0.1"
  spec.files = Dir["lib/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "pstore", "~> 0.1"
  spec.add_dependency "simple-result", "~> 0.3"
  spec.add_dependency "zeitwerk", "~> 2.6"

end
