module HybridApi
  # Every setting comes from here, each with a HYBRID_API_* env var override.
  # That's what makes this client reusable across projects/environments
  # without touching code - just point HYBRID_API_BASE_URL somewhere else.
  module Config
    def self.base_url
      ENV.fetch('HYBRID_API_BASE_URL', 'https://dummyjson.com')
    end

    def self.timeout_ms
      Integer(ENV.fetch('HYBRID_API_TIMEOUT_MS', '10000'))
    end

    def self.retry_attempts
      Integer(ENV.fetch('HYBRID_API_RETRY_ATTEMPTS', '3'))
    end

    def self.retry_backoff_ms
      Integer(ENV.fetch('HYBRID_API_RETRY_BACKOFF_MS', '300'))
    end

    def self.auth_username
      ENV.fetch('HYBRID_API_AUTH_USERNAME', 'emilys')
    end

    def self.auth_password
      ENV.fetch('HYBRID_API_AUTH_PASSWORD', 'emilyspass')
    end
  end
end
