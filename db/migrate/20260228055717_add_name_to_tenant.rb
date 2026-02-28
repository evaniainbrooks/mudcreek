class AddNameToTenant < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :name, :string, null: false, default: nil
  end
end
