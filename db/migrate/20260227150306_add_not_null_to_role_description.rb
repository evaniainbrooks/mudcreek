class AddNotNullToRoleDescription < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :roles, "description IS NOT NULL", name: "roles_description_null", validate: false
  end
end
