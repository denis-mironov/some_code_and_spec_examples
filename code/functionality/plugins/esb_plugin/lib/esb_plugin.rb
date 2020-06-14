require 'ostruct'

class MainHandler
  extend Jimson::Handler

  def make_debit_card_order(params)
    perform do
      request = Requests::MakeDebitCardOrderRequest.new(params)
      card_response = MakeDebitCardOrderHandler.new(@esb_adapter).handle(request)
      Responses::MakeDebitCardOrderResponse.new(card_response).to_hash
    end
  end

  def perform
    yield
  end
end
