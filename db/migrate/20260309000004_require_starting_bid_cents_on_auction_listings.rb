class RequireStartingBidCentsOnAuctionListings < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      change_column_null :auction_listings, :starting_bid_cents, false, 0
    end
  end
end
