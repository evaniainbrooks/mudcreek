class MakeListingOwnerNullableAddOwnerOrLotConstraint < ActiveRecord::Migration[8.1]
  def up
    change_column_null :listings, :owner_id, true
    add_check_constraint :listings,
      "owner_id IS NOT NULL OR lot_id IS NOT NULL",
      name: "listings_owner_or_lot_present",
      validate: false
  end

  def down
    remove_check_constraint :listings, name: "listings_owner_or_lot_present"
    change_column_null :listings, :owner_id, false
  end
end
