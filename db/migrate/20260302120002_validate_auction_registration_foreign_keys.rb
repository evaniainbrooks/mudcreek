class ValidateAuctionRegistrationForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :auction_registrations, :auctions
    validate_foreign_key :auction_registrations, :users
  end
end
