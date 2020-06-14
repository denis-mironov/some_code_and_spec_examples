class MakeDebitCardOrderHandler < BaseHandler
  def handle(request)
    esb.makeDebitCardOrder(request)
  end
end
