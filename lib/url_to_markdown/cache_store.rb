# frozen_string_literal: true

class UrlToMarkdown
  class CacheStore
    def exists?(_key)
      raise NotImplementedError, "Implement in subclass"
    end

    def find_by(_key)
      raise NotImplementedError, "Implement in subclass"
    end

    def store!(_key, _value)
      raise NotImplementedError, "Implement in subclass"
    end

    def invalidate!(_key)
      raise NotImplementedError, "Implement in subclass"
    end

    def clear!
      raise NotImplementedError, "Implement in subclass"
    end
  end
end
