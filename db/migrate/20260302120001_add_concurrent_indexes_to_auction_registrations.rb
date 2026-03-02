class AddConcurrentIndexesToAuctionRegistrations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # t.references already added individual indexes on auction_id and user_id;
    # add a unique composite index to enforce one registration per user per auction.
    add_index :auction_registrations, [:auction_id, :user_id], unique: true, algorithm: :concurrently
  end
end
