class ValidateNullifyForeignKeysForOrders < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :orders, :delivery_methods
    validate_foreign_key :orders, :discount_codes
    validate_foreign_key :order_items, :listings
  end
end
