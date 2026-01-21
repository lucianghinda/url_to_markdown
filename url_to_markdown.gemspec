# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "url_to_markdown"
  spec.version = "0.1.0"
  spec.authors = ["Lucian Ghinda"]
  spec.email = ["lucian@shortruby.com"]

  spec.summary = "Convert URLs to Markdown via Cloudflare Browser Rendering"
  spec.homepage = "https://github.com/lucianghinda/url_to_markdown"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.required_ruby_version = ">= 3.4.4"
  spec.files = Dir["lib/**/*", "README.md"]
  spec.require_paths = ["lib"]
  spec.license = "Apache-2.0"

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "pstore", "~> 0.1"
  spec.add_dependency "simple-result", "~> 0.3"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
