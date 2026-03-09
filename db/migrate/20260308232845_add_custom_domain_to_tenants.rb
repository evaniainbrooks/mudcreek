class AddCustomDomainToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :custom_domain, :string
  end
end
