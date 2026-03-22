class AddOwnerToQrCodes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :qr_codes, :owner, null: true, index: { algorithm: :concurrently }
  end
end
