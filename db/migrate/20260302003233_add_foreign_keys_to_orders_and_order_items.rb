class AddForeignKeysToOrdersAndOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :order_items, :listings, validate: false
    add_foreign_key :orders, :delivery_methods, validate: false
    add_foreign_key :orders, :discount_codes, validate: false
  end
end
