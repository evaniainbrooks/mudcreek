class Listings::StockMovement < ApplicationRecord
  include MultiTenant

  belongs_to :listing
  belongs_to :order_item, optional: true

  enum :kind,   { stock_in: "in", stock_out: "out" }
  enum :reason, { acquisition: "acquisition", manual_sale: "manual_sale", online_order: "online_order", adjustment: "adjustment" }

  monetize :unit_price_cents, allow_nil: true

  validates :quantity,      presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :transacted_on, presence: true

  after_create_commit { stock_in? ? listing.increment!(:quantity, quantity) : listing.decrement!(:quantity, quantity) }
  before_destroy      { stock_in? ? listing.decrement!(:quantity, quantity) : listing.increment!(:quantity, quantity) }
end
