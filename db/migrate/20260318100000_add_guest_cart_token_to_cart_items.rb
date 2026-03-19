class AddGuestCartTokenToCartItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :cart_items, :user_id, true
    add_column :cart_items, :guest_cart_token, :string
    add_index :cart_items, :guest_cart_token, algorithm: :concurrently

    # Drop the existing uniqueness index and recreate it scoped to authenticated users only
    remove_index :cart_items, name: "index_cart_items_on_user_id_and_listing_id", if_exists: true

    add_index :cart_items, [ :user_id, :listing_id ],
      unique: true,
      where: "user_id IS NOT NULL AND rental_start_at IS NULL AND invoice_item_id IS NULL",
      name: "index_cart_items_unique_user_listing",
      algorithm: :concurrently

    add_index :cart_items, [ :guest_cart_token, :listing_id ],
      unique: true,
      where: "guest_cart_token IS NOT NULL AND rental_start_at IS NULL",
      name: "index_cart_items_unique_guest_listing",
      algorithm: :concurrently
  end
end
