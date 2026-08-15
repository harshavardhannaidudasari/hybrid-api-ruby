require 'net/http'
require 'uri'
require 'json'
require_relative 'config'
require_relative 'retry_policy'

module HybridApi
  # Thin, reusable wrapper around stdlib Net::HTTP. Meant to be required by
  # *other* projects (a UI suite that wants to assert on backend state
  # before/after driving the browser or an app, for example) rather than used
  # only by the specs in this repo - see README "Using this as a library".
  #
  # Every request goes through RetryPolicy.with_retry, so a transient 5xx or
  # dropped connection against a real public API doesn't fail a spec outright.
  class ApiClient
    Result = Struct.new(:status, :body) do
      def json
        JSON.parse(body)
      end
    end

    def initialize(base_url: Config.base_url)
      @base_url = base_url
      @bearer_token = nil
    end

    # Returns self configured to send the given bearer token on every request.
    def with_bearer_token(token)
      @bearer_token = token
      self
    end

    def get(path, query = {})
      uri = build_uri(path, query)
      RetryPolicy.with_retry { perform(Net::HTTP::Get.new(uri)) }
    end

    def post(path, body = {})
      RetryPolicy.with_retry { perform(json_request(Net::HTTP::Post, path, body)) }
    end

    def put(path, body = {})
      RetryPolicy.with_retry { perform(json_request(Net::HTTP::Put, path, body)) }
    end

    def patch(path, body = {})
      RetryPolicy.with_retry { perform(json_request(Net::HTTP::Patch, path, body)) }
    end

    def delete(path)
      uri = build_uri(path)
      RetryPolicy.with_retry { perform(Net::HTTP::Delete.new(uri)) }
    end

    private

    def json_request(klass, path, body)
      uri = build_uri(path)
      request = klass.new(uri)
      request.body = body.to_json
      request['Content-Type'] = 'application/json'
      request
    end

    def build_uri(path, query = {})
      uri = URI.join(@base_url, path)
      uri.query = URI.encode_www_form(query) unless query.empty?
      uri
    end

    def perform(request)
      request['Authorization'] = "Bearer #{@bearer_token}" if @bearer_token
      request['Accept'] = 'application/json'

      uri = request.uri
      timeout_seconds = Config.timeout_ms / 1000.0

      response = Net::HTTP.start(uri.host, uri.port,
                                  use_ssl: uri.scheme == 'https',
                                  open_timeout: timeout_seconds,
                                  read_timeout: timeout_seconds) do |http|
        http.request(request)
      end

      Result.new(response.code.to_i, response.body)
    end
  end
end
