class ValidateForeignKeysOnOrdersAndOrderItems < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :order_items, :listings
    validate_foreign_key :orders, :delivery_methods
    validate_foreign_key :orders, :discount_codes
  end
end
