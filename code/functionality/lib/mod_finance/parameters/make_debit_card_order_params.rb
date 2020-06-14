module Finance
  class MakeDebitCardOrderParams
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
                  :address,
                  :request_id,
                  :request_owner

    def initialize(params)
      self.identity_number          = params.fetch('identity_number')
      self.code_word                = params.fetch('code_word', nil)
      self.product_type_id          = params.fetch('product_type_id')
      self.order_id                 = params.fetch('order_id')
      self.enable_sms               = params.fetch('enable_sms')
      self.delivery_method          = params.fetch('delivery_method')
      self.city_code                = params.fetch('city_code', nil)
      self.office_code              = params.fetch('office_code', nil)
      self.phone_number             = params.fetch('phone_number')
      self.additional_phone_number  = params.fetch('additional_phone_number', nil)
      self.email                    = params.fetch('email', nil)
      self.address                  = params.fetch('address', nil)
      self.request_id               = params.fetch('request_id')
      self.request_owner            = params.fetch('request_owner')
    end
  end
end
