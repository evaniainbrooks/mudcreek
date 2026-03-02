class CreateAuctionRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :auction_registrations do |t|
      t.references :auction, null: false, foreign_key: { validate: false }
      t.references :user, null: false, foreign_key: { validate: false }
      t.string :state, null: false, default: "pending"
      t.timestamps
    end
  end
end
