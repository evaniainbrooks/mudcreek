class AddEmailAddressToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :email_address, :string
  end
end
