# frozen_string_literal: true

require "fileutils"
require "pstore"

class UrlToMarkdown
  class CacheStore
    class PStore < UrlToMarkdown::CacheStore
      def initialize(path: "tmp/url_to_markdown.pstore")
        @path = path
        @store = ::PStore.new(path)
      end

      def exists?(key)
        @store.transaction(true) do
          !@store[key].nil?
        end
      rescue ::PStore::Error => e
        raise UrlToMarkdown::CacheReadError, e
      end

      def find_by(key)
        @store.transaction(true) do
          value = @store[key]
          raise UrlToMarkdown::CacheReadError.new(nil, "Cache miss") if value.nil?

          value
        end
      rescue ::PStore::Error => e
        raise UrlToMarkdown::CacheReadError, e
      end

      def store!(key, value)
        @store.transaction do
          @store[key] = value
        end
      rescue ::PStore::Error => e
        raise UrlToMarkdown::CacheWriteError, e
      end

      def invalidate!(key)
        @store.transaction do
          @store.delete(key)
        end
      rescue ::PStore::Error => e
        raise UrlToMarkdown::CacheWriteError, e
      end

      def clear!
        FileUtils.rm_f(@path)
      rescue StandardError => e
        raise UrlToMarkdown::CacheWriteError, e
      end
    end
  end
end
