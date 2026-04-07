class AddWebsiteToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :website, :string
  end
end
