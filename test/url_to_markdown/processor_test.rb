# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownProcessorTest < Minitest::Test
  def test_base_processor_requires_implementation
    processor = UrlToMarkdown::Processor.new

    assert_raises(NotImplementedError) { processor.convert("https://example.com") }
  end
end
