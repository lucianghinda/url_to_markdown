# frozen_string_literal: true

class UrlToMarkdown
  class Error < StandardError
    attr_reader :original_error

    def initialize(original_error = nil, message = nil)
      @original_error = original_error
      super(message || original_error&.message)
    end
  end

  class ConfigurationError < Error; end
  class MissingCredentialsError < ConfigurationError; end

  class NetworkError < Error; end
  class TimeoutError < NetworkError; end
  class ConnectionError < NetworkError; end

  class ApiError < Error
    attr_reader :status_code, :response_body

    def initialize(status_code = nil, response_body = nil, message: nil)
      @status_code = status_code
      @response_body = response_body
      super(nil, message)
    end
  end

  class AuthenticationError < ApiError; end

  class RateLimitError < ApiError
    attr_reader :retry_after

    def initialize(status_code = nil, response_body = nil, retry_after: nil, message: nil)
      @retry_after = retry_after
      super(status_code, response_body, message: message)
    end
  end

  class NotFoundError < ApiError; end
  class ServerError < ApiError; end
  class MissingResultKeyInResponse < ApiError; end

  class ValidationError < Error; end
  class InvalidUrlError < ValidationError; end

  class CacheError < Error; end
  class CacheReadError < CacheError; end
  class CacheWriteError < CacheError; end
end
