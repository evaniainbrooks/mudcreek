class AddDefaultDeliveryMethodSetToTenants < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :tenants, :default_delivery_method_set_id, :bigint

    add_index :tenants, :default_delivery_method_set_id, algorithm: :concurrently

    safety_assured do
      add_foreign_key :tenants, :listings_delivery_method_sets,
        column: :default_delivery_method_set_id,
        on_delete: :nullify
    end
  end
end
