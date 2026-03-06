class FixForeignKeyNullifyAndUniqueIndexForInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    # cart_items.invoice_item_id: switch to on_delete: :nullify
    remove_foreign_key :cart_items, :invoice_items
    add_foreign_key :cart_items, :invoice_items, on_delete: :nullify, validate: false

    # invoice_items.listing_id: switch to on_delete: :nullify
    remove_foreign_key :invoice_items, :listings
    add_foreign_key :invoice_items, :listings, on_delete: :nullify, validate: false
  end
end
