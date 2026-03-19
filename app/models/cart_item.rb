class CartItem < ApplicationRecord
  include MultiTenant

  belongs_to :user, optional: true
  belongs_to :listing
  belongs_to :invoice_item, optional: true
  has_one :rental_booking, dependent: :nullify, autosave: true

  validates :listing_id, uniqueness: { scope: :user_id, conditions: -> { where("user_id IS NOT NULL AND rental_start_at IS NULL").where("invoice_item_id IS NULL") } }
  validates :invoice_item_id, uniqueness: true, allow_nil: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validate :user_or_guest_token_present

  def rental?
    rental_start_at.present?
  end

  def from_invoice?
    invoice_item_id.present?
  end

  def effective_item_price
    if from_invoice?
      Money.new(invoice_item.amount_cents)
    elsif rental?
      Money.new(rental_price_cents.to_i)
    else
      Money.new(listing.price_cents)
    end
  end

  def effective_price
    return effective_item_price if from_invoice? || rental?
    Money.new(listing.price_cents * quantity)
  end

  private

  def user_or_guest_token_present
    errors.add(:base, "must belong to a user or have a guest cart token") if user_id.nil? && guest_cart_token.nil?
  end
end
