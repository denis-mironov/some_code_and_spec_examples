require_relative '../base_esb_service'

module EsbServices
  module ClientOrder
    class MakeDebitCard < BaseEsbService
      def initialize(params)
        @params = params
        super(service_group: CLIENT_ORDER, service_name: 'makeDebitCard', method: 'makeDebitCard')
      end

      def to_hash
        build_hash do |hash|
          hash[:idn]                   = @params.identity_number
          hash[:codeWord]              = @params.code_word unless @params.code_word.nil?
          hash[:productTypetId]        = @params.product_type_id
          hash[:orderId]               = @params.order_id
          hash[:enableSms]             = @params.enable_sms
          hash[:deliveryMethod]        = @params.delivery_method
          hash[:cityCode]              = @params.city_code unless @params.city_code.nil?
          hash[:officeCode]            = @params.office_code unless @params.office_code.nil?
          hash[:phoneNumber]           = @params.phone_number
          hash[:additionalPhoneNumber] = @params.additional_phone_number unless @params.additional_phone_number.nil?
          hash[:email]                 = @params.email unless @params.email.nil?
          hash[:address]               = @params.address unless @params.address.nil?
        end
      end
    end
  end
end
