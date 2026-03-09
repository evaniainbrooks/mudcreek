class RemoveBidIncrementCentsFromAuctionListings < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :auction_listings, :bid_increment_cents, :integer }
  end
end
