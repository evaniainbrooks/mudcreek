class ProxyBid < ApplicationRecord
  belongs_to :auction_listing
  belongs_to :auction_registration

  monetize :max_bid_cents, with_model_currency: :currency

  validates :max_bid_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :registration_must_be_approved
  validate :max_must_meet_minimum

  def currency = auction_listing.auction.tenant&.currency

  private

  def registration_must_be_approved
    return if auction_registration&.approved?
    errors.add(:auction_registration, "must be approved to place a proxy bid")
  end

  def max_must_meet_minimum
    return unless auction_listing
    return if max_bid_cents.nil?
    min = auction_listing.next_bid_amount
    return if max_bid_cents >= min.cents
    errors.add(:max_bid, "must be at least #{min.format}")
  end
end
