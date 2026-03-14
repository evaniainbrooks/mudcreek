class ValidateListingsOwnerOrLotConstraint < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    validate_check_constraint :listings, name: "listings_owner_or_lot_present"
  end
end
