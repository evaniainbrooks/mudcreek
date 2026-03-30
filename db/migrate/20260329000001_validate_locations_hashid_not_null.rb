class ValidateLocationsHashidNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :locations, name: "locations_hashid_not_null"
    change_column_null :locations, :hashid, false
    remove_check_constraint :locations, name: "locations_hashid_not_null"
  end

  def down
    add_check_constraint :locations, "hashid IS NOT NULL", name: "locations_hashid_not_null", validate: false
    change_column_null :locations, :hashid, true
  end
end
