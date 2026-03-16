class CreateWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :watchlist_items do |t|
      t.references :user,    null: false, foreign_key: { validate: false }
      t.references :listing, null: false, foreign_key: { validate: false }
      t.references :tenant,  null: false, foreign_key: { validate: false }
      t.timestamps
    end

    add_index :watchlist_items, [ :user_id, :listing_id ], unique: true
  end
end
