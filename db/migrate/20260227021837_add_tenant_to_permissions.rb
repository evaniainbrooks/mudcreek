class AddTenantToPermissions < ActiveRecord::Migration[8.1]
  def change
    safety_assured { add_reference :permissions, :tenant, null: true, foreign_key: true }
  end
end
