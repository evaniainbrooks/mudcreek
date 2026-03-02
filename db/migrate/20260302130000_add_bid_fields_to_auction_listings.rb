class AddBidFieldsToAuctionListings < ActiveRecord::Migration[8.1]
  def change
    add_column :auction_listings, :starting_bid_cents,  :integer
    add_column :auction_listings, :bid_increment_cents, :integer
    add_column :auction_listings, :reserve_price_cents, :integer
  end
end
