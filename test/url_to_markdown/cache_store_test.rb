# frozen_string_literal: true

require "test_helper"

class UrlToMarkdownCacheStoreTest < Minitest::Test
  def test_base_cache_store_requires_implementation
    store = UrlToMarkdown::CacheStore.new

    assert_raises(NotImplementedError) { store.exists?("key") }
    assert_raises(NotImplementedError) { store.find_by("key") }
    assert_raises(NotImplementedError) { store.store!("key", "value") }
    assert_raises(NotImplementedError) { store.invalidate!("key") }
    assert_raises(NotImplementedError) { store.clear! }
  end
end
