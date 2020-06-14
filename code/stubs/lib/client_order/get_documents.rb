require_relative '../../helpers'

GET_ORDER_DOCUMENTS = 'getDocuments'
GET_ORDER_DOCUMENTS_URL = url(CLIENT_ORDER, GET_ORDER_DOCUMENTS)

WebMock::Stub.request(
  url: GET_ORDER_DOCUMENTS_URL,
  request_body: nil,
  allow_any_request: true
) do |request|
  process_client_order_data(request.body)
end

WebMock::Stub.request(
  url: GET_ORDER_DOCUMENTS_URL,
  request_body: %(
    {
      "method": "#{GET_ORDER_DOCUMENTS}",
      "appid": "(.*)",
      "uid": "(.*)",
      "orderId": "(.*)",
      "requiredDocs": "[(.*)]",
      "lang": "(.*)",
      "format": "(.*)"
    })
) do |request|
  process_client_order_data(request.body)
end

class EsbResponseError < StandardError
	attr_accessor :error_body

	def initialize(message, object)
		super(message)
		self.error_body = object
	end
end

class ClientOrderDocumentsErrors < StandardError
	attr_accessor :error_body

	def initialize(message, object)
		super(message)
		self.error_body = object
	end
end

def process_client_order_data(request_body)
  params = JSON.parse(request_body)
  order_id = params['orderId']
  document_types = params['requiredDocs']

  begin
    status_code = 200
    @uid = "3440fb81-9b10-4095-9886-022d751c162a"
    product_id = DebitCardDataKeeper.find(order_id) # В случае, если запрашиваются документы при открытии карты

    if product_id
      get_client_order_documents_error        if product_id == '1598138890'
      client_order_documents_not_found_error  if product_id == '1598138945'
    end

    response = Array.new
    if document_types
      response << client_order_document
    else
      response << client_order_document
      response << client_order_sms_document
    end

    body =
      {
        uid: @uid,
        ErrCode: '0',
        ErrText: '',
        documents: response
      }

  rescue ClientOrderDocumentsErrors => e
    body = e.error_body
  end

  {
    status: status_code,
    headers: {'Content-Type' => 'application/json'},
    body: body.to_json
  }
end


def get_client_order_documents_error
	code = '1'
	message = 'Ошибка при запросе списка документов'
	raise_client_order_documents_error(code, message)
end

def client_order_documents_not_found_error
	code = '2115'
	message = 'Заявка на открытие продукта не найдена'
	raise_client_order_documents_error(code, message)
end

def raise_client_order_documents_error(code, message)
	raise ClientOrderDocumentsErrors.new(nil, client_order_documents_error_body(code, message))
end

def client_order_documents_error_body(code, message)
	{
		uid: @uid,
		ErrCode: code,
		ErrText: "АБС: ORA-20300: APP-TNG_ESB_INT.TNG_ESB_CLIENT_ORDER: #{message}"
	}
end

def client_order_document
  order_document_content("DEBIT_CARD_AG")
end

def client_order_sms_document
  order_document_content("SMS_DEBIT_CARD_AG")
end

def order_document_content(vid)
  card_name = {
    ru: "Пользовательское соглашение на открытие дебетовой карты",
    kz: "Дебеттік картаны ашуға арналған келісім",
    en: "User agreement for opening a debit card"
  }

  order_sms_name = {
    ru: "Пользовательское соглашение на подключение SMS-банкинга",
    kz: "SMS-банкингке қосылуға арналған келісім",
    en: "User agreement for SMS banking connection"
  }

  name = vid == 'DEBIT_CARD_AG' ? card_name : order_sms_name

  {
    vid:     vid,
    name:    name,
    type:    "PDF",
    content: "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ODQyXS9Hcm91cDw8L1MvVHJhbnNwYXJlbmN5L0NTL0RldmljZVJHQi9JIHRydWU+Pi9Db250ZW50cyAyIDAgUj4+CmVuZG9iagoKNCAwIG9iago8PC9UeXBlL1BhZ2VzCi9SZXNvdXJjZXMgMTEgMCBSCi9NZWRpYUJveFsgMCAwIDU5NSA4NDIgXQovS2lkc1sgMSAwIFIgXQovQ291bnQgMT4+CmVuZG9iagoKMTIgMCBvYmoKPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDQgMCBSCi9PcGVuQWN0aW9uWzEgMCBSIC9YWVogbnVsbCBudWxsIDBdCi9MYW5nKGVuLVVTKQo+PgplbmRvYmoKCjEzIDAgb2JqCjw8L0NyZWF0b3I8RkVGRjAwNTcwMDcyMDA2OTAwNzQwMDY1MDA3Mj4KL1Byb2R1Y2VyPEZFRkYwMDRDMDA2OTAwNjIwMDcyMDA2NTAwNEYwMDY2MDA2NjAwNjkwMDYzMDA2NTAwMjAwMDM1MDAyRTAwMzE+Ci9DcmVhdGlvbkRhdGUoRDoyMDE5MDUzMTE1MDEzMSswNicwMCcpPj4KZW5kb2JqCgp4cmVmCjAgMTQKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDA0NDMyIDAwMDAwIG4gCjAwMDAwMDAwMTkgMDAwMDAgbiAKMDAwMDAwMDE3NCAwMDAwMCBuIAowMDAwMDA0NTc1IDAwMDAwIG4gCjAwMDAwMDAxOTMgMDAwMDAgbiAKMDAwMDAwMzY3NCAwMDAwMCBuIAowMDAwMDAzNjk1IDAwMDAwIG4gCjAwMDAwMDM4OTAgMDAwMDAgbiAKMDAwMDAwNDE4MiAwMDAwMCBuIAowMDAwMDA0MzQ1IDAwMDAwIG4gCjAwMDAwMDQzNzcgMDAwMDAgbiAKMDAwMDAwNDY3NCAwMDAwMCBuIAowMDAwMDA0NzcxIDAwMDAwIG4gCnRyYWlsZXIKPDwvU2l6ZSAxNC9Sb290IDEyIDAgUgovSW5mbyAxMyAwIFIKL0lEIFsgPEUwRTlGNzk3NkVCQ0JCN0VFOTE5RkY1MkJENTMzQTVBPgo8RTBFOUY3OTc2RUJDQkI3RUU5MTlGRjUyQkQ1MzNBNUE+IF0KL0RvY0NoZWNrc3VtIC83MkJGMTgzRkRGNjYwOERBM0QzQjExNjkzRTY5RUM5OQo+PgpzdGFydHhyZWYKNDk0NgolJUVPRgo=",
    size:    26
  }
end
