class AddLocationToLedgers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :ledgers, :location, null: true, index: { algorithm: :concurrently }
    add_foreign_key :ledgers, :locations, validate: false
  end
end
