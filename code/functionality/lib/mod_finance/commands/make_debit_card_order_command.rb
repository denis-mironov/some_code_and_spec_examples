require_relative 'abstract_command'

module Finance
  class MakeDebitCardOrderCommand < AbstractCommand
    def execute
      order_response = @plugin.make_debit_card_order(@cmd_params)

      @bsm.send_success_response do |body|
        body[:order_response] = order_response
      end
    end
  end
end
