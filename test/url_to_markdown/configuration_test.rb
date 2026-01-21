# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownConfigurationTest < Minitest::Test
  def test_defaults
    config = UrlToMarkdown::Configuration.new

    assert_equal 30_000, config.cloudflare_timeout_ms
    assert_equal 5, config.cloudflare_cache_ttl
    assert_instance_of Logger, config.logger
    assert_equal UrlToMarkdown::Cloudflare::Processor, config.default_processor
  end

  def test_configuration_uses_environment_variables
    ENV["CLOUDFLARE_API_TOKEN"] = "env-token"
    ENV["CLOUDFLARE_ACCOUNT_ID"] = "env-account"

    config = UrlToMarkdown::Configuration.new

    assert_equal "env-token", config.cloudflare_api_token
    assert_equal "env-account", config.cloudflare_account_id
  ensure
    ENV.delete("CLOUDFLARE_API_TOKEN")
    ENV.delete("CLOUDFLARE_ACCOUNT_ID")
  end

  def test_missing_token_raises
    config = UrlToMarkdown::Configuration.new
    config.cloudflare_api_token = nil

    assert_raises(UrlToMarkdown::MissingCredentialsError) { config.cloudflare_api_token! }
  end

  def test_missing_account_id_raises
    config = UrlToMarkdown::Configuration.new
    config.cloudflare_account_id = nil

    assert_raises(UrlToMarkdown::MissingCredentialsError) { config.cloudflare_account_id! }
  end
end
