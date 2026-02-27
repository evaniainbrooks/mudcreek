class RemoveRedundantIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :permissions, name: "index_permissions_on_role_id"
    remove_index :cart_items, name: "index_cart_items_on_user_id"
    remove_index :listings_categories, name: "index_listings_categories_on_tenant_id"
    remove_index :listings, name: "index_listings_on_tenant_id"
  end
end
