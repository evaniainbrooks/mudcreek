class RenameIsDefaultToDefaultOnLocations < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    if column_exists?(:locations, :is_default)
      safety_assured { rename_column :locations, :is_default, :default }
    end

    if index_exists?(:locations, :tenant_id, name: "index_locations_on_tenant_id_default")
      remove_index :locations, name: "index_locations_on_tenant_id_default", algorithm: :concurrently
    end

    add_index :locations, :tenant_id,
              unique: true,
              where: '"default" = true',
              name: "index_locations_on_tenant_id_default",
              algorithm: :concurrently
  end

  def down
    remove_index :locations, name: "index_locations_on_tenant_id_default", algorithm: :concurrently
    safety_assured { rename_column :locations, :default, :is_default }
    add_index :locations, :tenant_id,
              unique: true,
              where: "is_default = true",
              name: "index_locations_on_tenant_id_default",
              algorithm: :concurrently
  end
end
