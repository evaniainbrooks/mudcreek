class AuctionListing < ApplicationRecord
  belongs_to :auction
  belongs_to :listing

  acts_as_list scope: :auction

  monetize :starting_bid_cents,  allow_nil: true
  monetize :bid_increment_cents, allow_nil: true
  monetize :reserve_price_cents, allow_nil: true

  has_many :bids, dependent: :destroy

  validates :listing_id, uniqueness: true

  def ends_at
    return nil unless auction.ends_at

    auction.ends_at + end_offset
  end

  def end_offset
    stagger = auction.end_time_stagger_interval || 0
    (position - 1) * stagger
  end
end
