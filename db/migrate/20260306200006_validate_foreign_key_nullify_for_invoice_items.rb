class ValidateForeignKeyNullifyForInvoiceItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Add unique partial index concurrently (requires disable_ddl_transaction!)
    add_index :cart_items, :invoice_item_id,
      unique: true,
      where: "invoice_item_id IS NOT NULL",
      name: "index_cart_items_on_invoice_item_id_unique",
      algorithm: :concurrently
    remove_index :cart_items,
      name: "index_cart_items_on_invoice_item_id",
      algorithm: :concurrently

    validate_foreign_key :cart_items, :invoice_items
    validate_foreign_key :invoice_items, :listings
  end
end
