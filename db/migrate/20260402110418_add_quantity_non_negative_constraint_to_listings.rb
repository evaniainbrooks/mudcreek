class AddQuantityNonNegativeConstraintToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    constraint_exists = connection.check_constraints(:listings)
                                  .any? { |c| c.name == "listings_quantity_non_negative" }

    unless constraint_exists
      safety_assured do
        add_check_constraint :listings, "quantity IS NULL OR quantity >= 0",
          name: "listings_quantity_non_negative", validate: false
      end
    end

    safety_assured { validate_check_constraint :listings, name: "listings_quantity_non_negative" }
  end

  def down
    remove_check_constraint :listings, name: "listings_quantity_non_negative"
  end
end
