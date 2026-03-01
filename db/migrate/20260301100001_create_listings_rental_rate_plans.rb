class CreateListingsRentalRatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_rental_rate_plans do |t|
      t.bigint  :tenant_id,        null: false
      t.bigint  :listing_id,       null: false
      t.string  :label,            null: false
      t.integer :duration_minutes, null: false
      t.integer :price_cents,      null: false
      t.integer :position,         null: false
      t.timestamps

      t.index [:listing_id, :position]
      t.index [:tenant_id]
    end

    add_check_constraint :listings_rental_rate_plans, "price_cents >= 0",      name: "listings_rental_rate_plans_price_cents_nonneg"
    add_check_constraint :listings_rental_rate_plans, "duration_minutes > 0",  name: "listings_rental_rate_plans_duration_minutes_positive"
    safety_assured do
      add_foreign_key :listings_rental_rate_plans, :listings
      add_foreign_key :listings_rental_rate_plans, :tenants
    end
  end
end
