class AddAddressRequiredToDeliveryMethods < ActiveRecord::Migration[8.1]
  def change
    add_column :delivery_methods, :address_required, :boolean, null: false, default: true
  end
end
