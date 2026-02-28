class AddCurrencyToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :currency, :string, null: false, default: "CAD"
  end
end
