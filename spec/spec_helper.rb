$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'hybrid_api'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
