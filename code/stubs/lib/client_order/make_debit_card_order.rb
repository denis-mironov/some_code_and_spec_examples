require_relative '../../helpers'

MAKE_DEBIT_CARD = 'makeDebitCard'
MAKE_DEBIT_CARD_URL = url(CLIENT_ORDER, MAKE_DEBIT_CARD)

WebMock::Stub.request(
	url: MAKE_DEBIT_CARD_URL,
	request_body: nil,
	allow_any_request: true
) do |request|
  params = JSON.parse(request.body)
	product_type_id = params['productTypetId']
	order_id = params['orderId']
	iin = params['idn']

	begin
    status_code = 200
		@uid = "3440fb81-9b10-4095-9886-022d751c162a"

    debit_card_esb_response_error                           if (product_type_id == '4070530655' && iin == '111111111111')
		client_tax_debt_error                                   if (product_type_id == '4070535641' && iin == '222222222222') # 2105
		client_unpaid_order_error                               if (product_type_id == '4077180745' && iin == '333333333333') # 2106
		client_inactive_taxpayer_error                          if (product_type_id == '4077188920' && iin == '444444444444') # 2107
		client_compliance_control_error                         if (product_type_id == '1598138974' && iin == '555555555555') # 2110
		individuals_related_with_special_treatment_to_the_bank  if (product_type_id == '1598139028' && iin == '666666666666') # 2111
		client_is_foreign_public_official                       if (product_type_id == '1598138977' && iin == '777777777777') # 2112
		code_word_wrong_format                                  if (product_type_id == '1598139031' && iin == '888888888888') # 2114

    DebitCardDataKeeper.find_and_update(
			product_type_id,
			order_id
		)

		body =
			{
				uid: @uid,
				ErrCode: '0',
				ErrText: '',
				status: "CREATED",
				requiredDocs: ["DEBIT_CARD_AG"]
			}

	rescue DebitCardErrors => e
    body = e.error_body

	rescue EsbResponseError => e
		body = e.error_body
	end

  {
    status: status_code,
    headers: {'Content-Type' => 'application/json'},
    body: body.to_json
  }
end

class EsbResponseError < StandardError
	attr_accessor :error_body

	def initialize(message, object)
		super(message)
		self.error_body = object
	end
end

class DebitCardErrors < StandardError
	attr_accessor :error_body

	def initialize(message, object)
		super(message)
		self.error_body = object
	end
end

def debit_card_esb_response_error
	code = '1'
  message = 'Ошибка при создании заявки на открытие карты'
	raise EsbResponseError.new(nil, debit_card_error_body(code, message))
end

def client_tax_debt_error
	code = '2105'
	message = 'У клиента имеется налоговая задолженность'
	raise_debit_card_error(code, message)
end

def client_unpaid_order_error
	code = '2106'
	message = 'Имеется не оплаченное инкассовое распоряжение или РПРО'
	raise_debit_card_error(code, message)
end

def client_inactive_taxpayer_error
	code = '2107'
	message = 'Клиент найден в базе бездействующий налогоплательщиков'
	raise_debit_card_error(code, message)
end

def client_compliance_control_error
	code = '2110'
	message = 'Клиент находится в списке запрета СКК'
	raise_debit_card_error(code, message)
end

def individuals_related_with_special_treatment_to_the_bank
	code = '2111'
	message = 'Данный сервис временно не доступен для лиц связанных с банком особыми отношениями'
	raise_debit_card_error(code, message)
end

def client_is_foreign_public_official
	code = '2112'
	message = 'Клиент банка является иностранным государственным служащим'
	raise_debit_card_error(code, message)
end

def code_word_wrong_format
	code = '2114'
	message = 'Неверный формат кодового слова'
	raise_debit_card_error(code, message)
end

def raise_debit_card_error(code, message)
	raise DebitCardErrors.new(nil, debit_card_error_body(code, message))
end

def debit_card_error_body(code, message)
	{
		uid: @uid,
		ErrCode: code,
		ErrText: "АБС: ORA-20300: APP-TNG_ESB_INT.TNG_ESB_DEBIT_CARDS: #{message}"
	}
end
