require 'ostruct'

class ProductDataFetcher
  def initialize(esb, product, client)
    @esb = esb
    @product = product
    @client = client
  end

  def request_params
    OpenStruct.new(client_id: @client.bank_client_id, product_id: @product.bank_product_id)
  end

  def fetch_account(account_id)
    account = find_or_create_account(account_id)

    if !@product.accounts.where(id: account.id).any?
      @product.accounts << account
    end

    details = @esb.getAccountDetails(OpenStruct.new(bank_account_id: account_id))

    account.update(currency: details.currency) if account.currency.nil?

    return {
        id:          account.id,
        currency:    details.currency,
        iban:        details.iban
    }
  end

  def find_or_create_account(account_id)
    account = Account.find_by(bank_account_id: account_id)

    if account.nil?
      return Account.create!(bank_account_id: account_id)
    else
      return account
    end
  end
end

class CreditDataFetcher < ProductDataFetcher
  def fetch
    @result = {
      id:        @product.id,
      type:      @product.product_type,
      parent_id: @product.parent_id
    }
    set_additional_info
    return @result
  end

  private

  def set_additional_info
    info = @esb.getCreditInfo(request_params)

    @result.merge!(
      {
        product_name:   info.product_name,
        product_number: info.product_number,
        start_date:     info.start_date,
        end_date:       info.end_date,
        next_pay_date:  info.next_pay_date,
        period_in_days: info.period_in_days,
        pay_day:        info.pay_day,
        currency:       info.currency,
        iban:           info.iban,
        no_debit:       info.no_debit,
        no_credit:      info.no_credit
      }
    )
  end
end

class DepositDataFetcher < ProductDataFetcher
  def fetch
    @result = {
        id:        @product.id,
        type:      @product.product_type,
        parent_id: @product.parent_id
    }
    set_additional_info
    set_accounts
    return @result
  end

  private

  def set_additional_info
    info = @esb.getDepositInfo(request_params)

    @result.merge!(
      {
        product_name:   info.product_name,
        product_number: info.product_number,
        start_date:     info.start_date,
        end_date:       info.end_date,
        period_in_days: info.period_in_days,
        currency:       info.currency,
        no_debit:       info.no_debit,
        no_credit:      info.no_credit,
        accounts:       info.accounts
      }
    )
  end

  def set_accounts
    @result[:accounts].map! do |account_details|
      fetch_account(account_details['id'])
    end
  end
end

class AccountDataFetcher < ProductDataFetcher
  def fetch
    @result = {
        id:        @product.id,
        type:      @product.product_type,
        parent_id: @product.parent_id
    }
    set_additional_info
    set_accounts
    return @result
  end

  private

  def set_additional_info
    info = @esb.getAccountInfo(request_params)

    @result.merge!(
      {
        product_name:   info.product_name,
        product_number: info.product_number,
        start_date:     info.start_date,
        currency:       info.currency,
        no_debit:       info.no_debit,
        no_credit:      info.no_credit,
        accounts:       info.accounts
      }
    )
  end

  def set_accounts
    @result[:accounts] = @result[:accounts].map do |account_details|
      fetch_account(account_details['id'])
    end
  end
end

class CardDataFetcher < ProductDataFetcher
  attr_reader :esb

  def fetch
    @result = {
      id:        @product.id,
      type:      @product.product_type,
      parent_id: @product.parent_id
    }

    main_card = @result.merge!(set_additional_info)
    # set_sub_cards if @product.children
    @result.except(:main_card)
  end

  def sub_cards
    esb.getCardDetails(OpenStruct.new(card_id: @product.bank_product_id)).cards
  end

  private

  def set_additional_info
    card_details(@product.bank_product_id)
  end

  def set_sub_cards
    cards = @product.children.map do |card|
      @main = {
        id:        card.id,
        type:      card.product_type,
        parent_id: card.parent_id
      }

      details = card_details(card.bank_product_id)
      @main.merge(details.except(:main_card))
    end

    @result[:sub_cards].replace cards
  end

  def card_details(bank_product_id)
    info = esb.getCardDetails(OpenStruct.new(card_id: bank_product_id))
    account_info = esb.getAccountDetails(OpenStruct.new(bank_account_id: info.account_id))

    return {
      account_id:    info.account_id,
      masked_number: info.masked_number,
      card_plastic:  info.card_plastic,
      card_status:   info.card_status,
      card_type:     info.card_type,
      currency:      info.currency,
      start_date:    info.start_date,
      close_date:    info.close_date,
      sub_cards:     info.cards,
      main_card:     info.main_card,
      iban:          account_info.iban
    }
  end
end
