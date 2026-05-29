class AddTaxExemptToChangeOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :change_orders, :tax_exempt, :boolean, default: false, null: false
  end
end
