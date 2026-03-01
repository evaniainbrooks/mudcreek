class AddNameToTenant < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :tenants, :name, :string
      Tenant.reset_column_information
      Tenant.find_each { |t| t.update_columns(name: "Default") }
      change_column_null :tenants, :name, false
    end
  end
end
