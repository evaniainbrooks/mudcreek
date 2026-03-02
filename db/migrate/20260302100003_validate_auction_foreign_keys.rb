class ValidateAuctionForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :auction_listings, :auctions
    validate_foreign_key :auction_listings, :listings
  end
end
