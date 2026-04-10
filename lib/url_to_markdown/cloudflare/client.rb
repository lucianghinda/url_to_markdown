# frozen_string_literal: true

require "faraday"
require "json"

class UrlToMarkdown
  module Cloudflare
    class Client
      BASE_URL = "https://api.cloudflare.com/client/v4"
      DEFAULT_ACTION_TIMEOUT = 30_000

      def initialize(token:, account_id:, action_timeout_in_milliseconds: nil)
        @token = token
        @account_id = account_id
        @timeout = (action_timeout_in_milliseconds || DEFAULT_ACTION_TIMEOUT) / 1000.0

        validate_credentials!
      end

      def markdown(url: nil, html: nil, wait_for_selector: nil, wait_for_timeout_in_milliseconds: nil, cache_ttl: nil,
                   scripts: nil, set_extra_http_headers: nil)
        validate_payload!(url: url, html: html)

        response = connection.post("accounts/#{@account_id}/browser-rendering/markdown") do |request|
          request.headers["Authorization"] = "Bearer #{@token}"
          request.headers["Content-Type"] = "application/json"
          request.options.timeout = @timeout
          request.params["cacheTTL"] = cache_ttl if cache_ttl
          request.body = JSON.generate(build_payload(
                                         url: url,
                                         html: html,
                                         wait_for_selector: wait_for_selector,
                                         wait_for_timeout_in_milliseconds: wait_for_timeout_in_milliseconds,
                                         scripts: scripts,
                                         set_extra_http_headers: set_extra_http_headers
                                       ))
        end

        handle_response(response)
      rescue Faraday::TimeoutError => e
        UrlToMarkdown::Result.failure(UrlToMarkdown::TimeoutError.new(e))
      rescue Faraday::ConnectionFailed => e
        UrlToMarkdown::Result.failure(UrlToMarkdown::ConnectionError.new(e))
      rescue Faraday::Error => e
        UrlToMarkdown::Result.failure(UrlToMarkdown::NetworkError.new(e))
      end

      SECURITY_CHECKPOINT_PATTERNS = [
        "vercel.link/security-checkpoint",  # Vercel Firewall
        "Vercel Security Checkpoint",
        "Just a moment",                    # Cloudflare challenge
        "Checking your browser",            # Cloudflare challenge
        "Enable JavaScript and cookies",    # Cloudflare challenge
        "cf-browser-verification",          # Cloudflare legacy
        "DDoS protection by"                # Generic DDoS protection
      ].freeze

      private

      def validate_credentials!
        return if @token && @account_id

        raise UrlToMarkdown::MissingCredentialsError.new(nil, "Missing Cloudflare credentials")
      end

      def validate_payload!(url:, html:)
        return if url || html

        raise UrlToMarkdown::ValidationError.new(nil, "Provide a URL or HTML")
      end

      def build_payload(url:, html:, wait_for_selector:, wait_for_timeout_in_milliseconds:, scripts:, set_extra_http_headers:)
        payload = {}
        payload[:url] = url if url
        payload[:html] = html if html
        payload[:waitForSelector] = { selector: wait_for_selector } if wait_for_selector
        payload[:waitForTimeout] = wait_for_timeout_in_milliseconds if wait_for_timeout_in_milliseconds
        payload[:addScriptTag] = Array(scripts).map { { content: it } } if scripts&.any?
        payload[:setExtraHTTPHeaders] = set_extra_http_headers if set_extra_http_headers
        payload
      end

      def security_checkpoint?(content)
        return false unless content.is_a?(String)

        SECURITY_CHECKPOINT_PATTERNS.any? { |pattern| content.include?(pattern) }
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL)
      end

      def handle_response(response)
        status = response.status
        body = response.body.to_s

        case status
        when 200..299
          data = JSON.parse(body)
          if data.key?("result")
            content = data["result"]
            if security_checkpoint?(content)
              UrlToMarkdown::Result.failure(UrlToMarkdown::SecurityCheckpointError.new(nil, "Blocked by security checkpoint"))
            else
              UrlToMarkdown::Result.success(content)
            end
          else
            UrlToMarkdown::Result.failure(UrlToMarkdown::MissingResultKeyInResponse.new(status, body))
          end
        when 401
          UrlToMarkdown::Result.failure(UrlToMarkdown::AuthenticationError.new(status, body))
        when 404
          UrlToMarkdown::Result.failure(UrlToMarkdown::NotFoundError.new(status, body))
        when 429
          retry_after = response.headers["Retry-After"]
          UrlToMarkdown::Result.failure(UrlToMarkdown::RateLimitError.new(status, body, retry_after: retry_after))
        when 500..599
          UrlToMarkdown::Result.failure(UrlToMarkdown::ServerError.new(status, body))
        else
          UrlToMarkdown::Result.failure(UrlToMarkdown::ApiError.new(status, body))
        end
      rescue JSON::ParserError
        UrlToMarkdown::Result.failure(UrlToMarkdown::ApiError.new(status, body))
      end
    end
  end
end
