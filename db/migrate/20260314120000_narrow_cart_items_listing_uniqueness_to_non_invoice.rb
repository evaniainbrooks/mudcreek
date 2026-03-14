class NarrowCartItemsListingUniquenessToNonInvoice < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :cart_items, name: :index_cart_items_on_user_id_and_listing_id_sale_only

    add_index :cart_items, [:user_id, :listing_id],
      unique: true,
      where: "(rental_start_at IS NULL AND invoice_item_id IS NULL)",
      name: :index_cart_items_on_user_id_and_listing_id_non_invoice,
      algorithm: :concurrently
  end
end
