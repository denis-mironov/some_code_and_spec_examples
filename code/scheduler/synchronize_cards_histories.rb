class SynchronizeCardsHistories
  def call
    product_cards = Product.where(product_type: 'card', history_synchronized: false)

    product_cards.each do |card|
      card_open_date = get_card_details(card)
      statement = get_card_statement(card, card_open_date)
      save_card_statement(card, statement) unless statement.nil?
    end unless product_cards.empty?

    synchronized_cards_update_history
  end

  private

  def synchronized_cards_update_history
    synchronized_product_cards = Product.where(product_type: 'card', history_synchronized: true)

    synchronized_product_cards.each do |card|
      card_synchronized_at = card.synchronized_at
      statement = get_card_statement(card, card_synchronized_at)
      save_card_statement(card, statement) unless statement.nil?
    end unless synchronized_product_cards.empty?
  end

  def get_card_details(card)
    esb.getCardDetails(OpenStruct.new(card_id: card.bank_product_id)).start_date.to_time
  end

  def get_card_statement(card, date)
    request = OpenStruct.new(
      card_id: card.bank_product_id,
      start_date: format_datetime(date),
      end_date: format_datetime(Time.now)
    )
    esb.getCardStatement(request)
  end

  def save_card_statement(card, statement)
    statement.each do |el|
      begin
        CardHistory.create(
          product_id:      card.id,
          operation_num:   el.operation_num,
          operation_date:  el.operation_date,
          amount:          el.amount,
          details:         el.details,
          message:         el.message,
          code:            el.code,
          currency:        el.currency,
          synchronized_at: Time.now
        )
      rescue ActiveRecord::RecordNotUnique => e
        Log.info(e.message)
        Log.info("[Plugin SchedulerError] Запись уже существует в базе данных. Исполнение таска продолжится")
        next
      end
    end

    card.update(
      history_synchronized: true,
      synchronized_at: Time.now
    )
  end

  def format_datetime(date)
    date.strftime("%FT%T%:z")
  end

  def esb
    @esb ||= Esb::EsbAdapter.new
  end
end
