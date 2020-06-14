ENV['APP_ENV'] = 'test'

require_relative '../config/boot'
require_relative 'helpers'
require_relative 'support/shared_contexts'
require 'database_cleaner'
require 'webmock/rspec'
require 'simplecov'
require 'rspec-parameterized'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true

    mocks.before_verifying_doubles do |reference|
      reference.target.define_attribute_methods if reference.target.respond_to? :define_attribute_methods
    end
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
