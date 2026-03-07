class MakeRentalBookingCartItemNullable < ActiveRecord::Migration[8.1]
  def change
    # Replace cascade-delete FK with nullify so bookings survive cart cleanup after payment
    remove_foreign_key :rental_bookings, :cart_items
    change_column_null :rental_bookings, :cart_item_id, true
    add_foreign_key :rental_bookings, :cart_items, on_delete: :nullify, validate: false
  end
end
