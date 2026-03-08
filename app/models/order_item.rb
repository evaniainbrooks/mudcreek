class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :listing, optional: true

  monetize :price_cents, with_model_currency: :currency

  validates :name, presence: true

  def currency = order.tenant&.currency
end
