class Bid < ApplicationRecord
  include NativeEnum

  belongs_to :auction_registration
  belongs_to :auction_listing

  native_enum :state, %i[placed cancelled]

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :registration_must_be_approved
  validate :cannot_outbid_yourself

  private

  def registration_must_be_approved
    return if auction_registration&.approved?
    errors.add(:auction_registration, "must be approved to place a bid")
  end

  def cannot_outbid_yourself
    current = auction_listing&.current_bid
    return unless current
    return unless current.auction_registration_id == auction_registration_id
    errors.add(:base, "you are already the highest bidder")
  end
end
