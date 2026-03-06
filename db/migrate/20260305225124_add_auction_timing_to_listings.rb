class AddAuctionTimingToListings < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :auction_listings, :ends_at, :datetime
    add_column :auction_listings, :extension_count, :integer, default: 0, null: false

    add_index :auction_listings, :ends_at, algorithm: :concurrently
  end
end
