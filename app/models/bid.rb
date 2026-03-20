class Bid < ApplicationRecord
  include NativeEnum

  attr_accessor :proxy_placed

  belongs_to :auction_registration
  belongs_to :auction_listing

  native_enum :state, %i[placed cancelled]

  monetize :amount_cents, with_model_currency: :currency

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :registration_must_be_approved, on: :create
  validate :listing_must_be_biddable, on: :create
  validate :listing_must_have_bid_configuration, on: :create
  validate :cannot_outbid_yourself, on: :create, unless: :proxy_placed
  validate :amount_must_equal_next_bid_amount, on: :create, unless: :proxy_placed

  def currency = auction_listing.auction.tenant&.currency

  private

  def registration_must_be_approved
    return if auction_registration&.approved?
    errors.add(:auction_registration, "must be approved to place a bid")
  end

  def listing_must_be_biddable
    return if auction_listing&.active?
    errors.add(:base, "bidding is not currently open for this listing")
  end

  def listing_must_have_bid_configuration
    return unless auction_listing
    return if auction_listing.auction.effective_bid_increment_schedule.present?
    errors.add(:base, "this listing does not have a bid increment configured")
  end

  def cannot_outbid_yourself
    current = auction_listing&.current_bid
    return unless current
    return unless current.auction_registration_id == auction_registration_id
    errors.add(:base, "you are already the highest bidder")
  end

  def amount_must_equal_next_bid_amount
    return unless auction_listing
    expected = auction_listing.next_bid_amount
    return if amount_cents == expected.cents
    errors.add(:amount, "must be #{expected.format}")
  end
end
