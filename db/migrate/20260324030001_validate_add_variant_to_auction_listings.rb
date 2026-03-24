class ValidateAddVariantToAuctionListings < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :auction_listings, :listings_variants
  end
end
