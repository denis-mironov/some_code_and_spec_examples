class DebitCardDataKeeper
  def self.save_card_products(product_id, order_id)
    product = DataKeeper.read(product_id)
    DataKeeper.keep(product_id, order_id) unless product
  end

  def self.find_and_update(product_id, order_id)
    product = DataKeeper.read(product_id)
    DataKeeper.keep(product_id, order_id) if product
  end

  def self.find(order_id)
    DataKeeper.read_by_value(order_id)
  end
end
