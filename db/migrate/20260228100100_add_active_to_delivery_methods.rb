class AddActiveToDeliveryMethods < ActiveRecord::Migration[8.1]
  def change
    add_column :delivery_methods, :active, :boolean, null: false, default: true
  end
end
