class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :listing, optional: true

  has_one :stock_movement, class_name: "Listings::StockMovement", dependent: :destroy

  monetize :price_cents, with_model_currency: :currency

  validates :name, presence: true

  def currency = order.tenant&.currency

  def record_stock_movement!
    return unless listing && listing.sale? && !listing.unlimited_quantity?
    listing.stock_movements.create!(
      kind:          :stock_out,
      reason:        :online_order,
      quantity:      1,
      transacted_on: order.created_at.to_date,
      order_item:    self
    )
  end
end
