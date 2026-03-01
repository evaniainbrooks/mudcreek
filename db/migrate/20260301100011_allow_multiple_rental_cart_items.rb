class AllowMultipleRentalCartItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :cart_items, [:user_id, :listing_id], if_exists: true
    add_index :cart_items, [:user_id, :listing_id],
      unique: true,
      where: "rental_start_at IS NULL",
      name: "index_cart_items_on_user_id_and_listing_id_sale_only",
      algorithm: :concurrently
  end
end
