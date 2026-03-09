class AuctionListing < ApplicationRecord
  include HasHashid

  belongs_to :auction
  belongs_to :listing

  acts_as_list scope: :auction

  monetize :starting_bid_cents,  with_model_currency: :currency, allow_nil: true
  monetize :bid_increment_cents, with_model_currency: :currency, allow_nil: true
  monetize :reserve_price_cents, with_model_currency: :currency, allow_nil: true

  has_many :bids, dependent: :destroy
  has_one :current_bid, -> {
    where(state: "placed")
    .order(amount_cents: :desc, created_at: :desc)
  }, class_name: "Bid"

  validates :listing_id, uniqueness: true

  after_create :initialize_end_time

  def currency = auction.tenant&.currency

  def ends_at_in_time_zone = ends_at&.in_time_zone(auction.timezone)

  def listing_state = listing.state
  def listing_state=(val)
    listing.update!(state: val)
  end

  def end_offset
    stagger = auction.end_time_stagger_interval || 0
    (position - 1) * stagger
  end

  def active?
    listing.on_sale? &&
      ends_at.present? &&
      Time.current < ends_at &&
      (auction.starts_at.nil? || auction.starts_at <= Time.current)
  end

  def next_bid_amount
    cents = if current_bid
      current_bid.amount_cents + (bid_increment_cents || 0)
    else
      starting_bid_cents || 0
    end
    Money.new(cents, currency)
  end

  private

  def generate_hashid
    return if hashid.present?
    loop do
      candidate = SecureRandom.alphanumeric(12)
      break self.hashid = candidate unless self.class.unscoped.exists?(hashid: candidate)
    end
  end

  def initialize_end_time
    update_column(
      :ends_at,
      auction.ends_at + end_offset
    )
  end
end
