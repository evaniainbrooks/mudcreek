class FixLocationsAndCheckIns < ActiveRecord::Migration[8.1]
  def up
    remove_index :locations, name: "index_locations_on_tenant_id"
    remove_index :check_ins, name: "index_check_ins_on_location_id"
    remove_index :check_ins, name: "index_check_ins_on_user_id"

    Location.where(hashid: nil).find_each do |location|
      location.send(:generate_hashid)
      location.save!(validate: false)
    end

    add_check_constraint :locations, "hashid IS NOT NULL", name: "locations_hashid_not_null", validate: false
  end

  def down
    remove_check_constraint :locations, name: "locations_hashid_not_null"

    add_index :locations, :tenant_id,   name: "index_locations_on_tenant_id"
    add_index :check_ins, :location_id, name: "index_check_ins_on_location_id"
    add_index :check_ins, :user_id,     name: "index_check_ins_on_user_id"
  end
end
