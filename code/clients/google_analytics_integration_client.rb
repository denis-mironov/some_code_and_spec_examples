# Class for interacting with Google Analytics API.

# Implemented to send information about course purchases and analyze the user’s path through the sales funnel.
# The 'ecommerceCheckout' and 'ecommercePurchase' events are sent from the backend.
# The remaining events are processed at the frontend.

# API: https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide
# Parameters: https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters

class GoogleAnalyticsIntegrationClient
  API_VERSION = 1

  attr_reader :url, :request_timeout, :tracking_id

  class BadResponseError < StandardError; end

  def initialize(url:, request_timeout:, tracking_id:)
    @url             = add_slash(url)
    @request_timeout = request_timeout
    @tracking_id     = tracking_id
  end

  def api_request(method, params)
    query_string = convert(params)
    base_url = url + method
    request = add_question_mark(base_url) + query_string
    log_request(request)

    begin
      RestClient::Request.execute(method: :post, url: request, timeout: request_timeout.to_i)
    rescue RestClient::Exception => e
      raise BadResponseError, e.message
    end
  end

  def collect(event_params)
    common_params = {
      v:   protocol_version,
      t:   hit_type,
      cid: nil,
      tid: tracking_id,
      ni:  not_interaction,
      cu:  nil,
      dl:  nil,
      ul:  user_language,
      de:  document_encoding,
      dt:  document_title,
      dh:  host_name,
      dr:  document_referer,
      ec:  event_category,
    }

    api_request('collect', common_params.merge(event_params).compact)
  end

  def ecommerce_checkout(order, location_url)
    order_item = order.order_items.first
    course = order_item.purchase_item.decorate.course

    params = {
      cid:   order.google_analytics_cid,
      dl:    location_url,
      ea:    event_action('checkout'),
      pa:    product_action('checkout'),
      pr1id: course.id,
      pr1qt: product_quantity,
      pr1ca: product_category(course),
      pr1pr: order_item.sum,
      pr1nm: course.title,
      cos:   purchase_step,
    }

    collect(params)
  end

  def ecommerce_purchase(order, location_url)
    order_item = order.order_items.first
    course = order_item.purchase_item.decorate.course

    params = {
      cid:   order.google_analytics_cid,
      dl:    location_url,
      cu:    currency_code,
      ea:    event_action('puchase'),
      pa:    product_action('purchase'),
      pr1id: course.id,
      pr1qt: product_quantity,
      pr1ca: product_category(course),
      pr1pr: order_item.sum,
      pr1nm: course.title,
      ta:    transaction_affiliation,
      ti:    transaction_id(order),
      tr:    order_item.sum,
      tt:    transaction_tax,
      ts:    transaction_shiping,
    }

    collect(params)
  end

  private

  def protocol_version
    API_VERSION
  end

  def hit_type
    'event'
  end

  def not_interaction
    1
  end

  def currency_code
    'RUB'
  end

  def user_language
    'ru'
  end

  def document_encoding
    'UTF-8'
  end

  def document_title
    'Courses'
  end

  def host_name
    Rails.application.config.action_controller.default_url_options[:host]
  end

  def document_referer
    Rails.application.routes.url_helpers.root_url
  end

  def event_category
    'EE'
  end

  def event_action(action)
    action == 'checkout' ? 'ecommerceCheckout' : 'ecommercePurchase'
  end

  def product_action(action)
    action == 'checkout' ? 'checkout' : 'purchase'
  end

  def product_category(course)
    course.creator&.teaches_subject&.title
  end

  def product_quantity
    1
  end

  def purchase_step
    1
  end

  # Formed with the prefix 'Oххх' (O - Order) to avoid layering if you need to pass the id of another object
  def transaction_id(order)
    'O' + order.id.to_s
  end

  def transaction_tax
    0
  end

  def transaction_shiping
    0
  end

  # According to customer documentation
  def transaction_affiliation
    'front.gusto.co.ua'
  end

  def add_slash(url)
    url += '/' unless url.ends_with?('/')
    url
  end

  def add_question_mark(method)
    method += '?' unless method.ends_with?('?')
    method
  end

  def convert(params)
    URI.encode_www_form(params)
  end

  def log_request(request)
    Rails.logger.info("Call Google Analytics: #{request}")
  end
end
