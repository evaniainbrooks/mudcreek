class CartItem < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :listing
  belongs_to :invoice_item, optional: true
  has_one :rental_booking, dependent: :destroy

  validates :listing_id, uniqueness: { scope: :user_id }, unless: :rental?
  validates :invoice_item_id, uniqueness: true, allow_nil: true

  def rental?
    rental_start_at.present?
  end

  def from_invoice?
    invoice_item_id.present?
  end

  def effective_price_cents
    return invoice_item.amount_cents if from_invoice?
    rental? ? rental_price_cents : listing.price_cents
  end
end
