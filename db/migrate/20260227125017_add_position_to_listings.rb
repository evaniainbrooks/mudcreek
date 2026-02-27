class AddPositionToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :listings, :position, :integer
    add_index :listings, [ :lot_id, :position ], unique: true, where: "lot_id IS NOT NULL", algorithm: :concurrently
  end
end
