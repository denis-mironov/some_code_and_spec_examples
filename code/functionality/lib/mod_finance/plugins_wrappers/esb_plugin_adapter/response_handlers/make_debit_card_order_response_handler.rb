module Plugin
  class MakeDebitCardOrderResponseHandler
    attr_accessor :response

    def handle_response(response)
      @response = response
    end

    def handle_error(error)
      Log.error(error)
      raise Plugin::MakeDebitCardOrderError.new(
        "Не удалось создать заявку на открытие карточного продукта",
        error
      )
    end
  end
end
