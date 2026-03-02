class AuctionListing < ApplicationRecord
  belongs_to :auction
  belongs_to :listing

  acts_as_list scope: :auction

  validates :listing_id, uniqueness: true
end
