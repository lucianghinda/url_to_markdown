# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownCloudflareProcessorTest < Minitest::Test
  def setup
    @config = UrlToMarkdown::Configuration.new
    @config.cloudflare_api_token = "token"
    @config.cloudflare_account_id = "account"
  end

  def test_invalid_url_raises
    processor = UrlToMarkdown::Cloudflare::Processor.new(config: @config)

    assert_raises(UrlToMarkdown::InvalidUrlError) { processor.convert("notaurl") }
  end

  def test_delegates_to_client
    processor = UrlToMarkdown::Cloudflare::Processor.new(config: @config)
    client = processor.instance_variable_get(:@client)
    client.expects(:markdown).with(url: "https://example.com", scripts: nil).returns(UrlToMarkdown::Result.success("ok"))

    result = processor.convert("https://example.com")

    assert result.success?
    assert_equal "ok", result.payload
  end

  def test_delegates_scripts_to_client
    processor = UrlToMarkdown::Cloudflare::Processor.new(config: @config)
    client = processor.instance_variable_get(:@client)
    scripts = ["document.querySelectorAll('nav').forEach(el => el.remove())"]
    client.expects(:markdown).with(url: "https://example.com", scripts: scripts).returns(UrlToMarkdown::Result.success("ok"))

    result = processor.convert("https://example.com", scripts: scripts)

    assert result.success?
  end
end
