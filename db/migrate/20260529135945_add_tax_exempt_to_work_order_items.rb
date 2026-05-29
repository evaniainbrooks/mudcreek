class AddTaxExemptToWorkOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_items, :tax_exempt, :boolean, default: false, null: false
  end
end
