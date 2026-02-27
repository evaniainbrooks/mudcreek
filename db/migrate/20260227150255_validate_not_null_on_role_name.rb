class ValidateNotNullOnRoleName < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :roles, name: "roles_name_null"
    change_column_null :roles, :name, false
    remove_check_constraint :roles, name: "roles_name_null"
  end

  def down
    add_check_constraint :roles, "name IS NOT NULL", name: "roles_name_null", validate: false
    change_column_null :roles, :name, true
  end
end
