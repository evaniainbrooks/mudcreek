class CreateBids < ActiveRecord::Migration[8.1]
  def change
    create_table :bids do |t|
      t.references :auction_registration, null: false, foreign_key: { validate: false }
      t.references :auction_listing,      null: false, foreign_key: { validate: false }
      t.integer :amount_cents, null: false
      t.string  :state,        null: false, default: "placed"
      t.timestamps
    end
  end
end
