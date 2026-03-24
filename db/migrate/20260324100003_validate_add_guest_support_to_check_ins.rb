class ValidateAddGuestSupportToCheckIns < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :check_ins, name: "check_ins_user_or_guest_name_present"
  end
end
