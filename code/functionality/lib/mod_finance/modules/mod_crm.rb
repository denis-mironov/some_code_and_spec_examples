require_relative 'base'

module ModCrm
  include Base

  class ModCrmWrapper < ModWrapper
    MODULE_NAME = 'CRM'.freeze
    BEHAVIORS = {
      make_debit_card_order_response: 'Response'
    }.freeze

    def initialize
      super(MODULE_NAME, BEHAVIORS)
    end

    def make_debit_card_order_response(status, body)
      response = MakeDebitCardOrderResponseBuilder.build_response(status, body)
      publish_command(:make_debit_card_order_response, response)
    end
  end

  class MakeDebitCardOrderResponseBuilder < ResponseBuilder
    def self.success(params:, order_response:)
      super(params: params) do
        {
          success: true,
          status: order_response.fetch('status'),
          documents: order_response.fetch('documents'),
          request_id: params.fetch('request_id')
        }
      end
    end

    def self.error(params:, error:)
      super(params: params) do
        {
          success: false,
          code: error.status,
          message: error.message,
          request_id: params.fetch('request_id')
        }
      end
    end
  end
end
