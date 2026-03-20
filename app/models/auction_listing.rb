class AuctionListing < ApplicationRecord
  include HasHashid

  belongs_to :auction
  belongs_to :listing

  acts_as_list scope: :auction

  monetize :starting_bid_cents,  with_model_currency: :currency
  validates :starting_bid_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  monetize :reserve_price_cents, with_model_currency: :currency, allow_nil: true

  has_many :bids, dependent: :destroy
  has_many :proxy_bids, dependent: :destroy
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
    if current_bid
      increment = effective_bid_increment_cents(current_bid.amount_cents)
      Money.new(current_bid.amount_cents + increment, currency)
    else
      Money.new(starting_bid_cents, currency)
    end
  end

  private

  def effective_bid_increment_cents(current_amount_cents)
    schedule = auction.effective_bid_increment_schedule
    schedule&.increment_for(current_amount_cents) || 0
  end

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
