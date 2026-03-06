class AuctionListing < ApplicationRecord
  include HasHashid

  belongs_to :auction
  belongs_to :listing

  acts_as_list scope: :auction

  monetize :starting_bid_cents,  allow_nil: true
  monetize :bid_increment_cents, allow_nil: true
  monetize :reserve_price_cents, allow_nil: true

  has_many :bids, dependent: :destroy
  has_one :current_bid, -> {
    where(state: "placed")
    .order(amount_cents: :desc, created_at: :desc)
  }, class_name: "Bid"

  validates :listing_id, uniqueness: true

  after_create :initialize_end_time

  def end_offset
    stagger = auction.end_time_stagger_interval || 0
    (position - 1) * stagger
  end

  def active?
    !listing.sold? && Time.current < ends_at
  end

  def next_bid_amount
    if current_bid
      current_bid.amount_cents + (bid_increment_cents || 0)
    else
      starting_bid_cents || 0
    end
  end

  private

  def initialize_end_time
    update_column(
      :ends_at,
      auction.ends_at + end_offset
    )
  end
end
