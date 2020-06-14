require_relative 'base_esb_object'

module EsbObject
  class MakeDebitCardOrderResponse < BaseEsbObject
    include DataMapper

    attr_accessor :status,
                  :documents

    def initialize(params)
      parse_parameters do
        self.status    = params.fetch('status')
        self.documents = params.fetch('requiredDocs')
      end
    end

    def status=(status)
      set_value(:status, status, Mappers::ClientOrderStatusMapper.new)
    end
  end
end