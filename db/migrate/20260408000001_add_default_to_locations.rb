class AddDefaultToLocations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :locations, :is_default, :boolean, null: false, default: false

    # Only one default location allowed per tenant
    add_index :locations, :tenant_id,
              unique: true,
              where: "is_default = true",
              name: "index_locations_on_tenant_id_default",
              algorithm: :concurrently
  end
end
