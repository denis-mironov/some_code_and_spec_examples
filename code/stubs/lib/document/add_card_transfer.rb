require 'time'
require_relative '../../helpers'

ADD_CARD_TRANSFER = 'addCardTransfer'
ADD_CARD_TRANSFER_URL = url(DOCUMENT, ADD_CARD_TRANSFER)

WebMock::Stub.request(
    url: ADD_CARD_TRANSFER_URL,
    request_body: %Q(
        {
          "agentIdProvider": "(.*)",
          "agentId": "(.*)",
          "accountId": "(.*)",
          "summ": "(.*)",
          "transId": "(.*)",
          "channel": "(.*)",
          "nazn": "(.*)",
          "method": "#{ADD_CARD_TRANSFER}",
          "appid": "(.*)",
          "uid": "(.*)"
        }
    ),
    response_body: %q({
    "uid": "3440fb81-9b10-4095-9886-022d751c162a",
    "ErrCode": "0",
    "ErrText": "",
    "fold": "eval('Time.now.to_i')"
})
)

WebMock::Stub.request(
    url: ADD_CARD_TRANSFER_URL,
    request_body: %Q(
        {
          "agentIdProvider": "(.*)",
          "agentId": "(.*)",
          "accountId": "(.*)",
          "summ": "(.*)",
          "fold": "(.*)",
          "transId": "(.*)",
          "channel": "(.*)",
          "nazn": "(.*)",
          "method": "#{ADD_CARD_TRANSFER}",
          "appid": "(.*)",
          "uid": "(.*)"
        }
    ),
    response_body: %q({
    "uid": "3440fb81-9b10-4095-9886-022d751c162a",
    "ErrCode": "0",
    "ErrText": "",
    "fold": "eval('Time.now.to_i')"
})
)
