class ValidateNotNullOnRoleDescription < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :roles, name: "roles_description_null"
    change_column_null :roles, :description, false
    remove_check_constraint :roles, name: "roles_description_null"
  end

  def down
    add_check_constraint :roles, "description IS NOT NULL", name: "roles_description_null", validate: false
    change_column_null :roles, :description, true
  end
end
