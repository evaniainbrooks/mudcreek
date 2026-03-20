class DropRedundantCartItemsIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :cart_items, name: :index_cart_items_on_user_id_and_listing_id_non_invoice, algorithm: :concurrently, if_exists: true
  end
end
