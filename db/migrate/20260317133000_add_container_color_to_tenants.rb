class AddContainerColorToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :container_color, :string
  end
end
