# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownCloudflareClientTest < Minitest::Test
  def setup
    @client = UrlToMarkdown::Cloudflare::Client.new(token: "token", account_id: "account")
  end

  def test_markdown_sends_post_with_authorization
    stub_cloudflare(status: 200, body: read_response("success"))

    @client.markdown(url: "https://example.com")

    assert_requested(:post, endpoint_url, headers: auth_headers)
  end

  def test_returns_result_on_success
    stub_cloudflare(status: 200, body: read_response("success"))

    result = @client.markdown(url: "https://example.com")

    assert result.success?
    assert_equal({ "markdown" => "# Hello\n\nWorld" }, result.payload)
  end

  def test_returns_error_when_result_key_missing
    stub_cloudflare(status: 200, body: read_response("success_missing_result"))

    result = @client.markdown(url: "https://example.com")

    assert result.failure?
    assert_instance_of UrlToMarkdown::MissingResultKeyInResponse, result.error
    assert_equal 200, result.error.status_code
  end

  def test_returns_authentication_error
    stub_cloudflare(status: 401, body: read_response("error_401"))

    result = @client.markdown(url: "https://example.com")

    assert result.failure?
    assert_instance_of UrlToMarkdown::AuthenticationError, result.error
  end

  def test_returns_rate_limit_error_with_retry_after
    stub_cloudflare(status: 429, body: read_response("error_429"), headers: { "Retry-After" => "120" })

    result = @client.markdown(url: "https://example.com")

    assert result.failure?
    assert_instance_of UrlToMarkdown::RateLimitError, result.error
    assert_equal "120", result.error.retry_after
  end

  def test_returns_server_error
    stub_cloudflare(status: 503, body: "{}")

    result = @client.markdown(url: "https://example.com")

    assert result.failure?
    assert_instance_of UrlToMarkdown::ServerError, result.error
  end

  def test_includes_wait_for_selector_in_request_body
    expected_body = JSON.generate({ url: "https://example.com", wait_for_selector: ".content" })

    stub_cloudflare(status: 200, body: read_response("success"), expected_body: expected_body)

    @client.markdown(url: "https://example.com", wait_for_selector: ".content")

    assert_requested(:post, endpoint_url, body: expected_body)
  end

  def test_raises_validation_error_when_no_url_or_html
    assert_raises(UrlToMarkdown::ValidationError) { @client.markdown }
  end

  private

  def endpoint_url
    "https://api.cloudflare.com/client/v4/accounts/account/browser-rendering/markdown"
  end

  def auth_headers
    { "Authorization" => "Bearer token", "Content-Type" => "application/json" }
  end

  def stub_cloudflare(status:, body:, headers: {}, expected_body: nil)
    stub = stub_request(:post, endpoint_url)
    stub = stub.with(headers: auth_headers, body: expected_body) if expected_body
    stub.to_return(status: status, body: body, headers: headers)
  end

  def read_response(name)
    path = File.join(__dir__, "..", "..", "data", "responses", "cloudflare", "#{name}.json")
    File.read(path)
  end
end
