module Responses
  class MakeDebitCardOrderResponse
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def to_hash
      {
        status: response.status,
        documents: response.documents
      }
    end
  end
end
