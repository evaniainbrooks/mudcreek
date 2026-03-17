class DropSingleColumnRedundantIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :watchlist_items,        name: "index_watchlist_items_on_user_id"
    remove_index :user_category_interests, name: "index_user_category_interests_on_user_id"
    remove_index :pages,                  name: "index_pages_on_tenant_id"
  end
end
