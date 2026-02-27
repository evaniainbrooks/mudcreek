class AddNotNullToRoleName < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :roles, "name IS NOT NULL", name: "roles_name_null", validate: false
  end
end
