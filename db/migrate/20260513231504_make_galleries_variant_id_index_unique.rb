class MakeGalleriesVariantIdIndexUnique < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :galleries, :variant_id, name: "index_galleries_on_variant_id", algorithm: :concurrently
    add_index :galleries, :variant_id, unique: true, name: "index_galleries_on_variant_id", algorithm: :concurrently
  end
end
