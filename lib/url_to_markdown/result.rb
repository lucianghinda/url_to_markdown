# frozen_string_literal: true

class UrlToMarkdown
  module Result
    class << self
      def success(value)
        if SimpleResult.respond_to?(:success)
          SimpleResult.success(value)
        else
          SimpleResult::Success.new(payload: value)
        end
      end

      def failure(error)
        if SimpleResult.respond_to?(:failure)
          SimpleResult.failure(error)
        else
          SimpleResult::Failure.new(error: error)
        end
      end
    end
  end
end
