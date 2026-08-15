require 'net/http'
require_relative 'config'

module HybridApi
  # Retries a request up to Config.retry_attempts times on a 5xx response or
  # a connection-level error, with a fixed backoff between attempts. 4xx
  # responses and assertion failures are never retried - deliberately dumb,
  # this only smooths over transient blips against a real public API.
  module RetryPolicy
    RETRYABLE_ERRORS = [
      Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout, SocketError
    ].freeze

    def self.with_retry(max_attempts: Config.retry_attempts, backoff_ms: Config.retry_backoff_ms)
      last_error = nil

      max_attempts.times do |attempt|
        begin
          response = yield
          return response if response.status < 500

          last_error = "Server error #{response.status} on attempt #{attempt + 1}"
        rescue *RETRYABLE_ERRORS => e
          last_error = e
        end

        sleep(backoff_ms / 1000.0) if attempt < max_attempts - 1
      end

      raise(last_error.is_a?(Exception) ? last_error : RuntimeError.new(last_error))
    end
  end
end
