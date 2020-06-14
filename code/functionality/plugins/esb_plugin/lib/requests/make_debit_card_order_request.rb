module Requests
  class MakeDebitCardOrderRequest
    attr_accessor :identity_number,
                  :code_word,
                  :product_type_id,
                  :order_id,
                  :enable_sms,
                  :delivery_method,
                  :city_code,
                  :office_code,
                  :phone_number,
                  :additional_phone_number,
                  :email,
                  :address

    def initialize(request)
      begin
        self.identity_number          = request.fetch('identity_number')
        self.code_word                = request.fetch('code_word')
        self.product_type_id          = request.fetch('product_type_id')
        self.order_id                 = request.fetch('order_id')
        self.enable_sms               = request.fetch('enable_sms')
        self.delivery_method          = request.fetch('delivery_method')
        self.city_code                = request.fetch('city_code')
        self.office_code              = request.fetch('office_code')
        self.phone_number             = request.fetch('phone_number')
        self.additional_phone_number  = request.fetch('additional_phone_number')
        self.email                    = request.fetch('email')
        self.address                  = request.fetch('address')
      rescue KeyError => e
        raise IncorrectRequestParameter.new("[#{self.class.name}]: #{e}")
      end
    end
  end
end
