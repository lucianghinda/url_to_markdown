# frozen_string_literal: true

require "logger"

class UrlToMarkdown
  class Configuration
    attr_accessor :cloudflare_api_token, :cloudflare_account_id, :cloudflare_timeout_ms, :cloudflare_cache_ttl,
                  :logger, :default_processor

    def initialize
      @cloudflare_api_token = ENV.fetch("CLOUDFLARE_API_TOKEN", nil)
      @cloudflare_account_id = ENV.fetch("CLOUDFLARE_ACCOUNT_ID", nil)
      @cloudflare_timeout_ms = 30_000
      @cloudflare_cache_ttl = 5
      @logger = Logger.new($stdout)
      @default_processor = UrlToMarkdown::Cloudflare::Processor
    end

    def cloudflare_api_token!
      return cloudflare_api_token if cloudflare_api_token && !cloudflare_api_token.empty?

      raise UrlToMarkdown::MissingCredentialsError.new(nil, "Missing Cloudflare API token")
    end

    def cloudflare_account_id!
      return cloudflare_account_id if cloudflare_account_id && !cloudflare_account_id.empty?

      raise UrlToMarkdown::MissingCredentialsError.new(nil, "Missing Cloudflare account ID")
    end
  end
end
