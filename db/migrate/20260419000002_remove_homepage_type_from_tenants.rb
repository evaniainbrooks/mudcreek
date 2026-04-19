class RemoveHomepageTypeFromTenants < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :tenants, :homepage_type, :string }
  end
end
