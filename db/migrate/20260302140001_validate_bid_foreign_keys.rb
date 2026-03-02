class ValidateBidForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :bids, :auction_registrations
    validate_foreign_key :bids, :auction_listings
  end
end
