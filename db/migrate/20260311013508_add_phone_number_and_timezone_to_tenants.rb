class AddPhoneNumberAndTimezoneToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :phone_number, :string
    add_column :tenants, :timezone, :string
  end
end
