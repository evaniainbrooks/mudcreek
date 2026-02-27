class ReplaceListingPositionIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :listings, [ :lot_id, :position ], if_exists: true
    add_index :listings, [ :tenant_id, :position ], unique: true, algorithm: :concurrently
  end
end
