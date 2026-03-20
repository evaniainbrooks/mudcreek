class CreateProxyBids < ActiveRecord::Migration[8.1]
  def change
    create_table :proxy_bids do |t|
      t.references :auction_listing, null: false, foreign_key: true
      t.references :auction_registration, null: false, foreign_key: true
      t.integer :max_bid_cents, null: false

      t.timestamps
    end

    add_index :proxy_bids, [ :auction_listing_id, :auction_registration_id ],
      unique: true,
      name: "index_proxy_bids_on_listing_and_registration"
  end
end
