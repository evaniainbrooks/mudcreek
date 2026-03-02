class AddConcurrentIndexesToAuctionListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # t.references in CreateAuctionListings already added a non-unique index on listing_id;
    # replace it with a unique one. The auction_id index is already present.
    remove_index :auction_listings, :listing_id, algorithm: :concurrently
    add_index :auction_listings, :listing_id, unique: true, algorithm: :concurrently
  end
end
