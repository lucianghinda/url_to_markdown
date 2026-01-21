# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownTest < Minitest::Test
  def test_convert_returns_cached_content
    logger = mock("logger")
    logger.expects(:info).times(3)

    cache_store = mock("cache")
    cache_store.expects(:exists?).with("https://example.com").returns(true)
    cache_store.expects(:find_by).with("https://example.com").returns("cached")

    result = UrlToMarkdown.new(
      url: "https://example.com",
      processor: Class.new(UrlToMarkdown::Processor),
      logger: logger,
      cache_store: cache_store
    ).convert

    assert result.success?
    assert_equal "cached", result.payload
  end

  def test_convert_delegates_to_processor_on_cache_miss
    logger = mock("logger")
    logger.expects(:info).twice

    cache_store = mock("cache")
    cache_store.expects(:exists?).with("https://example.com").returns(false)
    cache_store.expects(:store!).with("https://example.com", "markdown")

    processor_class = Class.new(UrlToMarkdown::Processor) do
      def convert(_url)
        UrlToMarkdown::Result.success("markdown")
      end
    end

    result = UrlToMarkdown.new(
      url: "https://example.com",
      processor: processor_class,
      logger: logger,
      cache_store: cache_store
    ).convert

    assert result.success?
    assert_equal "markdown", result.payload
  end

  def test_convert_does_not_cache_failures
    logger = mock("logger")
    logger.expects(:info).twice

    cache_store = mock("cache")
    cache_store.expects(:exists?).with("https://example.com").returns(false)
    cache_store.expects(:store!).never

    processor_class = Class.new(UrlToMarkdown::Processor) do
      def convert(_url)
        UrlToMarkdown::Result.failure(UrlToMarkdown::ApiError.new(500, "boom"))
      end
    end

    result = UrlToMarkdown.new(
      url: "https://example.com",
      processor: processor_class,
      logger: logger,
      cache_store: cache_store
    ).convert

    assert result.failure?
  end

  def test_convert_logs_start_and_completion
    logger = mock("logger")
    logger.expects(:info).with("UrlToMarkdown: converting https://example.com")
    logger.expects(:info).with("UrlToMarkdown: completed https://example.com")

    processor_class = Class.new(UrlToMarkdown::Processor) do
      def convert(_url)
        UrlToMarkdown::Result.success("ok")
      end
    end

    result = UrlToMarkdown.new(
      url: "https://example.com",
      processor: processor_class,
      logger: logger
    ).convert

    assert result.success?
  end

  def test_convert_wraps_errors
    logger = mock("logger")
    logger.expects(:info)

    processor_class = Class.new(UrlToMarkdown::Processor) do
      def convert(_url)
        raise "Boom"
      end
    end

    result = UrlToMarkdown.new(
      url: "https://example.com",
      processor: processor_class,
      logger: logger
    ).convert

    assert result.failure?
    assert_instance_of UrlToMarkdown::Error, result.error
  end
end
