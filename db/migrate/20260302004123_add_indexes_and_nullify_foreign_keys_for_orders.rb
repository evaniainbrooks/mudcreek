class AddIndexesAndNullifyForeignKeysForOrders < ActiveRecord::Migration[8.1]
  def change
    # Re-add foreign keys with on_delete: :nullify
    remove_foreign_key :orders, :delivery_methods
    remove_foreign_key :orders, :discount_codes
    remove_foreign_key :order_items, :listings

    add_foreign_key :orders, :delivery_methods, on_delete: :nullify, validate: false
    add_foreign_key :orders, :discount_codes, on_delete: :nullify, validate: false
    add_foreign_key :order_items, :listings, on_delete: :nullify, validate: false

  end
end
