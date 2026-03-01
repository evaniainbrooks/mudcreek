class Order < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :delivery_method, optional: true
  belongs_to :discount_code,   optional: true
  has_many   :order_items, dependent: :destroy

  enum :status, { pending: "pending", paid: "paid", cancelled: "cancelled" }

  monetize :subtotal_cents
  monetize :tax_cents
  monetize :discount_cents
  monetize :delivery_price_cents
  monetize :total_cents

  before_create :assign_number

  private

  def assign_number
    self.number = loop do
      candidate = "MC-#{SecureRandom.alphanumeric(8).upcase}"
      break candidate unless Order.exists?(number: candidate)
    end
  end
end
