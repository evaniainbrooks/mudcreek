class AddQuantityCheckConstraintToListings < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :listings, "quantity >= 0", name: "listings_quantity_non_negative", validate: false
  end
end
