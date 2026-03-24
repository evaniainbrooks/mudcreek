class AddGuestSupportToCheckIns < ActiveRecord::Migration[8.1]
  def change
    add_column :check_ins, :guest_name, :string
    change_column_null :check_ins, :user_id, true
    add_check_constraint :check_ins,
      "(user_id IS NOT NULL OR guest_name IS NOT NULL)",
      name: "check_ins_user_or_guest_name_present",
      validate: false
  end
end
