# frozen_string_literal: true

class UrlToMarkdown
  class Processor
    def initialize(logger: nil, cache_store: nil)
      @logger = logger
      @cache_store = cache_store
    end

    def convert(_url)
      raise NotImplementedError, "Implement in subclass"
    end
  end
end
