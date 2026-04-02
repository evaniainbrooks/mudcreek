class AddQuantityNonNegativeConstraintToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_check_constraint :listings, "quantity IS NULL OR quantity >= 0",
      name: "listings_quantity_non_negative", validate: false, if_not_exists: true
    validate_check_constraint :listings, name: "listings_quantity_non_negative"
  end
end
