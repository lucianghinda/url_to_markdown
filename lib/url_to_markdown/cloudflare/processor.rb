# frozen_string_literal: true

require "uri"

class UrlToMarkdown
  module Cloudflare
    class Processor < UrlToMarkdown::Processor
      def initialize(config: UrlToMarkdown.configuration, logger: nil, cache_store: nil)
        super(logger: logger, cache_store: cache_store)
        @config = config
        @client = UrlToMarkdown::Cloudflare::Client.new(
          token: @config.cloudflare_api_token!,
          account_id: @config.cloudflare_account_id!,
          action_timeout_in_milliseconds: @config.cloudflare_timeout_ms
        )
      end

      def convert(url)
        validate_url!(url)
        @client.markdown(url: url)
      end

      private

      def validate_url!(url)
        uri = URI.parse(url)
        return if uri.is_a?(URI::HTTP) && !uri.host.nil?

        raise UrlToMarkdown::InvalidUrlError.new(nil, "Invalid URL")
      rescue URI::InvalidURIError
        raise UrlToMarkdown::InvalidUrlError.new(nil, "Invalid URL")
      end
    end
  end
end
