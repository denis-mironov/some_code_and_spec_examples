require 'json-schema'
require 'faraday/detailed_logger'
require_relative 'base_adapter'

module Esb
  class EsbAdapter < BaseAdapter
    def makeDebitCardOrder(params)
      response = do_request EsbServices::ClientOrder::MakeDebitCard.new(params)
      EsbObject::MakeDebitCardOrderResponse.new(response)
    end
  end
end
