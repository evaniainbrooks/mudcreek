class AddHashidToAuctionListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :auction_listings, :hashid, :string unless column_exists?(:auction_listings, :hashid)

    safety_assured do
      execute <<~SQL
        UPDATE auction_listings
        SET hashid = encode(sha256(auction_listings.id::text::bytea), 'hex')
        WHERE hashid IS NULL
      SQL

      change_column_null :auction_listings, :hashid, false
    end

    add_index :auction_listings, :hashid, unique: true, algorithm: :concurrently unless index_exists?(:auction_listings, :hashid)
  end

  def down
    remove_column :auction_listings, :hashid
  end
end
