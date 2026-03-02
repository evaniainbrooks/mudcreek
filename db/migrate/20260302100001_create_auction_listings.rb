class CreateAuctionListings < ActiveRecord::Migration[8.1]
  def change
    create_table :auction_listings do |t|
      t.references :auction, null: false, foreign_key: { validate: false }
      t.references :listing, null: false, foreign_key: { validate: false }
      t.integer :position
      t.timestamps
    end
  end
end
