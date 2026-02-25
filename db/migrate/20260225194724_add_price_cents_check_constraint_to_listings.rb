class AddPriceCentsCheckConstraintToListings < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :listings, "price_cents >= 0", name: "listings_price_cents_non_negative", validate: false
  end
end
