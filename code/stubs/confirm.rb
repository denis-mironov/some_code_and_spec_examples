require_relative '../../helpers'

CONFIRM_ORDER = 'confirm'
CONFIRM_ORDER_URL = url(CLIENT_ORDER, CONFIRM_ORDER)

WebMock::Stub.request(
  url: CONFIRM_ORDER_URL,
  request_body: %(
    {
      "method": "#{CONFIRM_ORDER}",
      "appid": "(.*)",
      "uid": "(.*)",
      "orderId": "(.*)"
    })
) do |request|
    params = JSON.parse(request.body)
    order_id = params['orderId']

    begin
      status_code = 200
      @uid = "3440fb81-9b10-4095-9886-022d751c162a"
      product_id = DebitCardDataKeeper.find(order_id) # В случае, если подтверждается заявка на открытие карты

      confirm_client_order_error     if product_id == '4077218911'
      confirm_order_not_found_error  if product_id == '4077213541'

      body =
        {
          uid: @uid,
          ErrCode: '0',
          ErrText: '',
          status: "PROCESSING"
        }

    rescue ConfirmClientOrderErrors => e
      body = e.error_body
    end

  {
    status: status_code,
    headers: {'Content-Type' => 'application/json'},
    body: body.to_json
  }
end

class ConfirmClientOrderErrors < StandardError
	attr_accessor :error_body

	def initialize(message, object)
		super(message)
		self.error_body = object
	end
end

def confirm_client_order_error
  code = '1'
	message = 'Ошибка при подтверждении заявки'
	confirm_client_order_error(code, message)
end

def confirm_order_not_found_error
	code = '2115'
	message = 'Заявка на открытие продукта не найдена'
	confirm_client_order_error(code, message)
end

def confirm_client_order_error(code, message)
	raise ConfirmClientOrderErrors.new(nil, confirm_client_order_error_body(code, message))
end

def confirm_client_order_error_body(code, message)
	{
		uid: @uid,
		ErrCode: code,
		ErrText: "АБС: ORA-20300: APP-TNG_ESB_INT.TNG_ESB_CLIENT_ORDERS: #{message}"
	}
end
