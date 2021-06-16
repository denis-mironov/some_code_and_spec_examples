class GoogleAnalyticsEcommerceJob < ApplicationJob
  include Sidekiq::Status::Worker

  def perform(order, location_url, product_action:)
    allowed_actions = %w(ecommerce_purchase ecommerce_checkout)
    unless allowed_actions.include?(product_action)
      raise "Unknown product_action #{product_action}, must be one of #{allowed_actions.join(', ')}"
    end

    google_client_id = order.google_analytics_cid

    unless google_client_id
      Rails.logger.warn("Skip ecommerce send, google_analytics_cid is empty for #{order.id}")
      return
    end

    ga_integration = Rails.application.config.ga_integration
    ga_integration.public_send(product_action, order, location_url)
  end
end
