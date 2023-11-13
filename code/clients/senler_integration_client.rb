# A class for interacting with the Senler API.

# Senler: https://help.senler.ru/
# API: https://help.senler.ru/razrabotchikam/api

class SenlerIntegrationClient
  API_VERSION = 2
  REQUEST_MASK = '[FILTERED]'.freeze
  MASKED_KEYS = %i{access_token}.freeze

  attr_reader :url, :request_timeout

  class BadResponseError < StandardError; end

  def initialize(url:, request_timeout:)
    @url             = add_slash(url)
    @request_timeout = request_timeout.to_i
  end

  def api_request(method, params)
    base_url = url + method

    begin
      resource = RestClient::Resource.new(
        base_url,
        timeout: request_timeout.to_i
      )
      response = resource.post(params)
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      raise BadResponseError, e.message
    ensure
      log_data(base_url, params, response)
    end
  end

  def add_subscriber(vk_group_id:, subscribers_group_id:, access_token:, vk_user_id:)
    params = {
      v:               API_VERSION,
      vk_group_id:     vk_group_id,
      subscription_id: subscribers_group_id,
      access_token:    access_token,
      vk_user_id:      vk_user_id,
    }

    api_request('subscribers/add', params)
  end

  def add_subscribers_group(vk_group_id:, access_token:, title:)
    params = {
      v:                  API_VERSION,
      vk_group_id:        vk_group_id,
      access_token:       access_token,
      name:               title,
      inactive:           1,
      hide_subscriptions: 1,
    }

    api_request('subscriptions/add', params)
  end

  private

  def add_slash(url)
    url += '/' unless url.ends_with?('/')
    url
  end

  def log_data(url, params, response)
    Rails.logger.info("Call Senler: #{url} with params: #{mask(params)}. Response: #{response}")
  end

  def mask(params)
    params.map { |k, v| [k, MASKED_KEYS.include?(k) ? REQUEST_MASK : v] }.to_h
  end
end
