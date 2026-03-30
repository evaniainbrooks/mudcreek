class AddLocationToQrCodes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :qr_codes, :location, null: true, index: false
    add_index :qr_codes, :location_id, unique: true, algorithm: :concurrently
    add_foreign_key :qr_codes, :locations, validate: false
  end
end
