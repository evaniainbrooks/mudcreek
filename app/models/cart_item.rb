class CartItem < ApplicationRecord
  include MultiTenant

  belongs_to :user
  belongs_to :listing
  has_one :rental_booking, dependent: :destroy

  validates :listing_id, uniqueness: { scope: :user_id }

  def rental?
    rental_start_at.present?
  end

  def effective_price_cents
    rental? ? rental_price_cents : listing.price_cents
  end
end
