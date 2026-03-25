class AddHashidToLocations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :locations, :hashid, :string
    add_index :locations, :hashid, unique: true, algorithm: :concurrently
  end
end
