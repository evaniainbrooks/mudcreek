class ValidateWatchlistItemForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :watchlist_items, :users
    validate_foreign_key :watchlist_items, :listings
    validate_foreign_key :watchlist_items, :tenants
  end
end
