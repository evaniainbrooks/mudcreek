class RenameIsDefaultToDefaultOnLocations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    safety_assured { rename_column :locations, :is_default, :default }

    add_index :locations, :tenant_id,
              unique: true,
              where: '"default" = true',
              name: "index_locations_on_tenant_id_default",
              algorithm: :concurrently
  end
end
