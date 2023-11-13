shared_examples 'prepare ecommerce data' do
  before do
    allow(ga_integration).to receive(:collect).with(collect_params)
  end

  it 'prepares params and send them to #collect' do
    subject

    expect(ga_integration).to have_received(:collect).with(collect_params)
  end
end

shared_examples 'logs request' do |error_response|
  it 'logs request' do
    error_response.nil? ? subject : (expect { subject }.to raise_error(described_class::BadResponseError))

    expect(Rails.logger).to have_received(:info).with(/Call Google Analytics/)
  end
end

shared_examples 'send request' do |error_response|
  it 'send post request with params to Google Analytics' do
    error_response.nil? ? subject : (expect { subject }.to raise_error(described_class::BadResponseError))

    expect(RestClient::Request).to have_received(:execute).with(
      method: :post,
      url: request,
      timeout: request_timeout
    )
  end
end

RSpec.describe GoogleAnalyticsIntegration do
  let(:request_url) { 'http://www.google-analytics.com' }
  let(:request_timeout) { 60 }
  let(:tracking_id) { 'test_tracking_id' }
  let(:ga_integration) {
    GoogleAnalyticsIntegration.new(
      url:             request_url,
      request_timeout: request_timeout,
      tracking_id:     tracking_id,
    )
  }

  let(:order) { create(:order, google_analytics_cid: 'ga_client_id') }
  let(:order_item) { create(:order_item, order_id: order.id, sum: 1000) }
  let(:course) { order_item.purchase_item.course }
  let(:subject_title) { course.creator.teaches_subject.title }
  let(:location_url) { 'test_location_url' }
  let(:transaction_id) { 'O' + order.id.to_s }
  let(:request_method) { 'collect' }
  let(:api_version) { described_class::API_VERSION }
  let(:hit_type) { 'event' }
  let(:common_params) {
    {
      v:   api_version,
      t:   hit_type,
      tid: tracking_id,
    }
  }

  let(:event_params) {
    {
      cid:   order.google_analytics_cid,
      dl:    location_url,
      pr1id: course.id,
      pr1ca: subject_title,
      pr1pr: order_item.sum,
      pr1nm: course.title,
    }
  }

  context '#ecommerce_checkout' do
    let(:collect_params) { hash_including(event_params) }

    subject { ga_integration.ecommerce_checkout(order, location_url) }

    include_examples 'prepare ecommerce data'
  end

  context '#ecommerce_purchase' do
    let(:collect_params) { hash_including(event_params.merge(ti: transaction_id)) }

    subject { ga_integration.ecommerce_purchase(order, location_url) }

    include_examples 'prepare ecommerce data'
  end

  context '#collect' do
    subject { ga_integration.collect(event_params) }

    let(:request_params) { hash_including(common_params.merge(event_params)) }

    before do
      allow_any_instance_of(described_class).to receive(:host_name).and_return('host_name')
      allow_any_instance_of(described_class).to receive(:document_referer).and_return('referer')
      allow(ga_integration).to receive(:api_request).with(request_method, request_params)
    end

    it 'collect all params and send them to #api_request' do
      subject

      expect(ga_integration).to have_received(:api_request).with(request_method, request_params)
    end
  end

  context '#api_request' do
    subject { ga_integration.api_request(request_method, request_params) }

    let(:request_params) { common_params.merge(event_params) }
    let(:request_base_url) { request_url + '/' + request_method }
    let(:query_string) { URI.encode_www_form(request_params) }
    let(:request) { request_base_url + '?' + query_string }

    before do
      allow(Rails.logger).to receive(:info)
    end

    context 'when request to google analytics is success' do
      before do
        allow(RestClient::Request).to receive(:execute).with(
          method: :post,
          url: request,
          timeout: request_timeout
        )
      end

      include_examples 'logs request'
      include_examples 'send request'
    end

    context 'when request to google analytics is fail' do
      before do
        allow(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception)
      end

      include_examples 'logs request', 'error'
      include_examples 'send request', 'error'

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::BadResponseError)
      end
    end
  end
end
