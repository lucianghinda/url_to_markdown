# frozen_string_literal: true

require "test_helper"
require "fileutils"

class UrlToMarkdownCacheStorePStoreTest < Minitest::Test
  def setup
    @path = File.join(__dir__, "..", "..", "..", "tmp", "test.pstore")
    FileUtils.mkdir_p(File.dirname(@path))
    FileUtils.rm_f(@path)
    @store = UrlToMarkdown::CacheStore::PStore.new(path: @path)
  end

  def test_exists_returns_false_for_missing_key
    refute @store.exists?("missing")
  end

  def test_exists_returns_true_after_store
    @store.store!("key", "value")

    assert @store.exists?("key")
  end

  def test_find_by_returns_cached_content
    @store.store!("key", "value")

    assert_equal "value", @store.find_by("key")
  end

  def test_find_by_raises_for_missing_key
    assert_raises(UrlToMarkdown::CacheReadError) { @store.find_by("missing") }
  end

  def test_invalidate_removes_cached_content
    @store.store!("key", "value")
    @store.invalidate!("key")

    refute @store.exists?("key")
  end

  def test_clear_removes_cache_file
    @store.store!("key", "value")
    @store.clear!

    refute File.exist?(@path)
  end
end
