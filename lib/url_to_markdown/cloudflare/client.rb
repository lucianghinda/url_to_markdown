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

      def markdown(url: nil, html: nil, wait_for_selector: nil, wait_for_timeout_in_milliseconds: nil, cache_ttl: nil)
        validate_payload!(url: url, html: html)

        response = connection.post("accounts/#{@account_id}/browser-rendering/markdown") do |request|
          request.headers["Authorization"] = "Bearer #{@token}"
          request.headers["Content-Type"] = "application/json"
          request.options.timeout = @timeout
          request.body = JSON.generate(build_payload(
                                         url: url,
                                         html: html,
                                         wait_for_selector: wait_for_selector,
                                         wait_for_timeout_in_milliseconds: wait_for_timeout_in_milliseconds,
                                         cache_ttl: cache_ttl
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

      private

      def validate_credentials!
        return if @token && @account_id

        raise UrlToMarkdown::MissingCredentialsError.new(nil, "Missing Cloudflare credentials")
      end

      def validate_payload!(url:, html:)
        return if url || html

        raise UrlToMarkdown::ValidationError.new(nil, "Provide a URL or HTML")
      end

      def build_payload(url:, html:, wait_for_selector:, wait_for_timeout_in_milliseconds:, cache_ttl:)
        payload = {}
        payload[:url] = url if url
        payload[:html] = html if html
        payload[:wait_for_selector] = wait_for_selector if wait_for_selector
        if wait_for_timeout_in_milliseconds
          payload[:wait_for_timeout_in_milliseconds] =
            wait_for_timeout_in_milliseconds
        end
        payload[:cache_ttl] = cache_ttl if cache_ttl
        payload
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
            UrlToMarkdown::Result.success(data["result"])
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
