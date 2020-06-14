require_relative 'helpers/rails_helper.rb'

describe ModFinance, 'Создание заявки на открытие платежной карты' do
  subject { described_class.new }
  let(:publisher) { Base::ModWrapper }

  let(:iin_for_error_response) { "111111111111" }

  let(:params) do
    {
      "identity_number" => "111111111111",
      "code_word" => "КакоеТоКодовоеСлово",
      "product_type_id" => "4065788238",
      "order_id" => "bd265a47-83e0-4082-afcf-4065788238",
      "enable_sms" => true,
      "delivery_method" => "courier",
      "city_code" => "002",
      "office_code" => "002-009-01",
      "phone_number" => "+77051111111",
      "additional_phone_number" => "+77062222222",
      "email" => "example@gmail.com",
      "address" => "Bayzakova str.",
      "request_id" => "d651673d-9442-49f2-9472-dfdh7tyy564u",
      "request_owner" => "CRM"
    }
  end

  before do
    allow_any_instance_of(publisher).to receive(:publish_command)
  end

  it 'возвращает статус заявки и список ID документов для конкретного пользователя' do
    VCR.use_cassette("make_debit_card_order/success_response") do |cassette|
      expect_any_instance_of(publisher).to receive(:publish_command).with(
        :make_debit_card_order_response,
        success_response
      )

      subject.MakeDebitCardOrder(params)
    end
  end

  it 'возвращает ошибку - make_debit_card_order_error' do
    run_error_test(
      "make_debit_card_order_error",
      "Не удалось создать заявку на открытие карточного продукта",
      "4070530655"
    )
  end

  it 'возвращает ошибку - client_tax_debt_error' do
    run_error_test(
      "client_tax_debt_error",
      "У клиента имеется налоговая задолженность",
      "4070535641"
    )
  end

  it 'возвращает ошибку - client_unpaid_order_error' do
    run_error_test(
      "client_unpaid_order_error",
      "Имеется неоплаченное инкассовое распоряжение или РПРО",
      "4077180745"
    )
  end

  it 'возвращает ошибку - client_inactive_taxpayer_error' do
    run_error_test(
      "client_inactive_taxpayer_error",
      "Клиент найден в базе бездействующих налогоплательщиков",
      "4077188920"
    )
  end

  it 'возвращает ошибку - client_compliance_control_error' do
    run_error_test(
      "client_compliance_control_error",
      "Клиент находится в списке запрета СКК",
      "1598138974"
    )
  end

  it 'возвращает ошибку - individuals_related_with_special_treatment_to_the_bank' do
    run_error_test(
      "individuals_related_with_special_treatment_to_the_bank",
      "Данный сервис временно не доступен для лиц связанных с банком особыми отношениями",
      "1598139028"
    )
  end

  it 'возвращает ошибку - client_is_foreign_public_official' do
    run_error_test(
      "client_is_foreign_public_official",
      "Клиент банка является иностранным государственным служащим",
      "1598138977"
    )
  end

  it 'возвращает ошибку - code_word_wrong_format' do
    run_error_test(
      "code_word_wrong_format",
      "Неверный формат кодового слова",
      "1598139031"
    )
  end

  private

  def run_error_test(error_code, error_message, product_type_id)
    params["identity_number"] = iin_for_error_response
    params["product_type_id"] = product_type_id

    VCR.use_cassette("make_debit_card_order/#{error_code}") do |cassette|
      expect_any_instance_of(publisher).to receive(:publish_command).with(
        :make_debit_card_order_response,
        error_response(
          "#{error_code}",
          "#{error_message}"
        )
      )
      subject.MakeDebitCardOrder(params)
    end
  end

  def success_response
    {
      success: true,
      status: 'created',
      documents: ["DEBIT_CARD_AG"],
      request_id: params.fetch('request_id'),
      mod_sender: "Finance",
      request_owner: "CRM"
    }
  end

  def error_response(code, message)
    {
      success: false,
      code: code,
      message: message,
      request_id: params.fetch('request_id'),
      mod_sender: "Finance",
      request_owner: "CRM"
    }
  end
end
