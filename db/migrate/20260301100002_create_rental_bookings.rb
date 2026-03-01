class CreateRentalBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :rental_bookings do |t|
      t.bigint   :tenant_id,    null: false
      t.bigint   :listing_id,   null: false
      t.bigint   :cart_item_id, null: false
      t.datetime :start_at,     null: false
      t.datetime :end_at,       null: false
      t.datetime :expires_at,   null: false
      t.timestamps

      t.index [:cart_item_id], unique: true
      t.index [:listing_id, :start_at, :end_at]
      t.index [:expires_at]
      t.index [:tenant_id]
    end

    safety_assured do
      add_foreign_key :rental_bookings, :listings
      add_foreign_key :rental_bookings, :cart_items, on_delete: :cascade
      add_foreign_key :rental_bookings, :tenants
    end
  end
end
