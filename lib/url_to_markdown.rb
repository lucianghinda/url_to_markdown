# frozen_string_literal: true

require "zeitwerk"
require "simple_result"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("errors" => "Error", "pstore" => "PStore")
loader.setup

class UrlToMarkdown
  def initialize(url:, processor: nil, logger: nil, cache_store: nil)
    @url = url
    @processor_class = processor || self.class.configuration.default_processor
    @logger = logger || self.class.configuration.logger
    @cache_store = cache_store
  end

  def convert
    @logger.info("UrlToMarkdown: converting #{@url}")

    if @cache_store&.exists?(@url)
      cached = @cache_store.find_by(@url)
      result = UrlToMarkdown::Result.success(cached)
      @logger.info("UrlToMarkdown: cache hit for #{@url}")
      @logger.info("UrlToMarkdown: completed #{@url}")
      return result
    end

    processor = @processor_class.new(logger: @logger, cache_store: @cache_store)
    result = processor.convert(@url)

    @cache_store.store!(@url, result.payload) if @cache_store && result.respond_to?(:success?) && result.success?

    @logger.info("UrlToMarkdown: completed #{@url}")
    result
  rescue StandardError => e
    wrapped = e.is_a?(UrlToMarkdown::Error) ? e : UrlToMarkdown::Error.new(e)
    UrlToMarkdown::Result.failure(wrapped)
  end

  class << self
    def configuration
      @configuration ||= UrlToMarkdown::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def convert(url, **)
      new(url: url, **).convert
    end
  end
end

loader.eager_load
