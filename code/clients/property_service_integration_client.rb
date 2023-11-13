# frozen_string_literal: true

# Class for integration with Property Service.
module PropertyServiceIntegrationClient
  include HTTParty
  attr_reader :property

  class BadResponseError < StandardError; end

  base_uri Rails.application.secrets.property_service_url

  AUTHORIZATION_TOKEN = "Bearer #{Rails.application.secrets.property_service_bearer_token}"
  SIMILAR_PROPERTIES_PATH = '/properties/similar'

  def initialize(property)
    @property = property
  end

  # All httparty gem errors are subclasses of StandardError
  def api_request(path, params)
    response = self.class.get(
      path,
      body: params.to_json,
      headers: request_headers
    )

    handle(response)
  rescue StandardError => e
    log_error(e.inspect)
    error_response
  end

  def similar_properties(**args)
    api_request(SIMILAR_PROPERTIES_PATH, request_params(args))
  end

  private

  def request_params(args)
    {
      marketing_type: property.marketing_type,
      property_type: property.property_type,
      lat: property.latitude,
      lng: property.longitude,
      living_space_min: args[:living_space_min],
      living_space_max: args[:living_space_max],
      limit: args[:limit],
      from_date: Rails.env.production? ? args[:from_date] : nil
    }
  end

  def request_headers
    {
      'Content-type' => 'application/json',
      'Authorization' => AUTHORIZATION_TOKEN
    }
  end

  def handle(response)
    raise BadResponseError, (response.parsed_response || response.inspect) unless response.success?

    success_response(JSON.parse(response.body)['data'])
  end

  def log_error(log_message)
    Rails.logger.error(
      "Property Service API request (property_uid: #{property.uid}) executed with error: #{log_message}"
    )
  end

  def success_response(properties)
    {
      success: true,
      properties: properties
    }
  end

  def error_response
    {
      success: false,
      properties: []
    }
  end
end
