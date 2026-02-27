class AddTenantToRoles < ActiveRecord::Migration[8.1]
  def change
    safety_assured { add_reference :roles, :tenant, null: true, foreign_key: true }
  end
end
