ENV['RAILS_ENV'] = ENV['APP_ENV'] = 'test'

require_relative '../../../config/boot'
require_relative '../../../lib/mod_finance'
require_relative '../../support/webmock'
require 'database_cleaner'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = ROOT_PATH.join("spec/integrational_spec/fixtures/vcr_cassettes")
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    FactoryBot.find_definitions

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
