class ValidateQuantityCheckConstraintOnListings < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :listings, name: "listings_quantity_non_negative"
  end
end
