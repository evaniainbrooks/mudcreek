class AddVariantNameToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :variant_name, :string
  end
end
